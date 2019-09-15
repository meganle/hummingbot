# distutils: language=c++
from decimal import Decimal
import logging
from typing import (
    List,
    Tuple,
    Optional,
    Dict
)

from hummingbot.core.clock cimport Clock
from hummingbot.logger import HummingbotLogger
from hummingbot.core.event.event_listener cimport EventListener
from hummingbot.core.data_type.limit_order cimport LimitOrder
from hummingbot.core.data_type.limit_order import LimitOrder
from hummingbot.core.network_iterator import NetworkStatus
from hummingbot.market.market_base import (
    MarketBase,
    OrderType,
    TradeType
)

from hummingbot.strategy.market_symbol_pair import MarketSymbolPair
from hummingbot.strategy.strategy_base import StrategyBase

from libc.stdint cimport int64_t
from hummingbot.core.data_type.order_book cimport OrderBook
from datetime import datetime

NaN = float("nan")
s_decimal_zero = Decimal(0)
ds_logger = None

cdef class HelloWorldStrategy(StrategyBase):
    OPTION_LOG_NULL_ORDER_SIZE = 1 << 0
    OPTION_LOG_REMOVING_ORDER = 1 << 1
    OPTION_LOG_ADJUST_ORDER = 1 << 2
    OPTION_LOG_CREATE_ORDER = 1 << 3
    OPTION_LOG_MAKER_ORDER_FILLED = 1 << 4
    OPTION_LOG_STATUS_REPORT = 1 << 5
    OPTION_LOG_MAKER_ORDER_HEDGED = 1 << 6
    OPTION_LOG_ALL = 0x7fffffffffffffff
    CANCEL_EXPIRY_DURATION = 60.0

    @classmethod
    def logger(cls) -> HummingbotLogger:
        global ds_logger
        if ds_logger is None:
            ds_logger = logging.getLogger(__name__)
        return ds_logger

    def __init__(self,
                 market_infos: List[MarketSymbolPair],
                 logging_options: int = OPTION_LOG_ALL):

        if len(market_infos) < 1:
            raise ValueError(f"market_infos must not be empty.")

        super().__init__()
        self._market_infos = {
            (market_info.market, market_info.trading_pair): market_info
            for market_info in market_infos
        }
        self._all_markets_ready = False
        self._place_orders = True
        self._logging_options = logging_options

        cdef:
            set all_markets = set([market_info.market for market_info in market_infos])

        self.c_add_markets(list(all_markets))

    @property
    def active_bids(self) -> List[Tuple[MarketBase, LimitOrder]]:
        return self._sb_order_tracker.active_bids

    @property
    def active_asks(self) -> List[Tuple[MarketBase, LimitOrder]]:
        return self._sb_order_tracker.active_asks

    @property
    def active_maker_orders(self) -> List[Tuple[MarketBase, LimitOrder]]:
        return self._sb_order_tracker.active_maker_orders

    @property
    def in_flight_cancels(self) -> Dict[str, float]:
        return self._sb_order_tracker.in_flight_cancels

    @property
    def market_info_to_active_orders(self) -> Dict[MarketSymbolPair, List[LimitOrder]]:
        return self._sb_order_tracker.market_pair_to_active_orders

    @property
    def logging_options(self) -> int:
        return self._logging_options

    @logging_options.setter
    def logging_options(self, int64_t logging_options):
        self._logging_options = logging_options

    @property
    def place_orders(self):
        return self._place_orders

    def format_status(self) -> str:
        cdef:
            MarketBase maker_market
            OrderBook maker_order_book
            str maker_symbol
            str maker_base
            str maker_quote
            double maker_base_balance
            double maker_quote_balance
            list lines = []
            list warning_lines = []
            dict market_info_to_active_orders = self.market_info_to_active_orders
            list active_orders = []

        for market_info in self._market_infos.values():
            active_orders = self.market_info_to_active_orders.get(market_info, [])

            warning_lines.extend(self.network_warning([market_info]))

            assets_df = self.wallet_balance_data_frame([market_info])
            # lines.extend(["", "  Assets:"] + ["    " + line for line in str(assets_df).split("\n")])
            base_asset_amt = str(market_info.market.get_balance(market_info.base_asset))
            quote_asset_amt = str(market_info.market.get_balance(market_info.quote_asset))
            lines.extend(["", "  Assets:"] + ["    " + base_asset_amt + "    " + market_info.base_asset] +
                         ["    " + quote_asset_amt + "  " + market_info.quote_asset])

        if len(warning_lines) > 0:
            lines.extend(["", "*** WARNINGS ***"] + warning_lines)

        return "\n".join(lines)

    cdef c_start(self, Clock clock, double timestamp):
        StrategyBase.c_start(self, clock, timestamp)

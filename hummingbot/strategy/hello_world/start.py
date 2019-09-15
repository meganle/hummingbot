from typing import (
    List,
    Tuple,
)

from hummingbot.client.settings import EXAMPLE_PAIRS
from hummingbot.strategy.market_symbol_pair import MarketSymbolPair
from hummingbot.strategy.hello_world import (
    HelloWorldStrategy
)
from hummingbot.strategy.hello_world.hello_world_config_map import hello_world_config_map


def start(self):
    try:
        market = hello_world_config_map.get("market").value.lower()
        market_symbol = hello_world_config_map.get("market_symbol").value
        raw_market_symbol = EXAMPLE_PAIRS.get(market)

        try:
            assets: Tuple[str, str] = self._initialize_market_assets(market, [raw_market_symbol])[0]
        except ValueError as e:
            self._notify(str(e))
            return

        market_names: List[Tuple[str, List[str]]] = [(market, [raw_market_symbol])]

        self._initialize_wallet(token_symbols=list(set(assets)))
        self._initialize_markets(market_names)
        self.assets = set(assets)

        maker_data = [self.markets[market], raw_market_symbol] + list(assets)
        self.market_symbol_pairs = [MarketSymbolPair(*maker_data)]

        strategy_logging_options = HelloWorldStrategy.OPTION_LOG_ALL

        self.strategy = HelloWorldStrategy(market_infos=[MarketSymbolPair(*maker_data)],
                                           market_symbol=market_symbol,
                                           logging_options=strategy_logging_options)
    except Exception as e:
        self._notify(str(e))
        self.logger().error("Unknown error during initialization.", exc_info=True)

from hummingbot.client.config.config_var import ConfigVar
from hummingbot.client.config.config_validators import (
    is_exchange,
    is_valid_market_symbol,
)
from hummingbot.client.settings import (
    required_exchanges,
)


def symbol_prompt():
    market = hello_world_config_map.get("market").value
    return "Enter a single token to fetch its balance on %s >>> " % market


# checks if the symbol pair is valid
def is_valid_market_symbol_pair(value: str) -> bool:
    market = hello_world_config_map.get("market").value
    return is_valid_market_symbol(market, value)


hello_world_config_map = {
    "market": ConfigVar(key="market",
                        prompt="Enter the name of the exchange >>> ",
                        validator=is_exchange,
                        on_validated=lambda value: required_exchanges.append(value)),
    "market_symbol_pair": ConfigVar(key="market_symbol_pair",
                                    prompt=symbol_prompt,
                                    validator=is_valid_market_symbol_pair),
}

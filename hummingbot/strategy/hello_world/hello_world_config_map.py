from hummingbot.client.config.config_var import ConfigVar
from hummingbot.client.config.config_validators import (
    is_exchange,
)
from hummingbot.client.settings import (
    required_exchanges,
)


def symbol_prompt():
    market = hello_world_config_map.get("market").value
    return "Enter a single token to fetch its balance on %s >>> " % market


hello_world_config_map = {
    "market": ConfigVar(key="market",
                        prompt="Enter the name of the exchange >>> ",
                        validator=is_exchange,
                        on_validated=lambda value: required_exchanges.append(value)),
    "market_symbol": ConfigVar(key="market_symbol",
                               prompt=symbol_prompt,
                               type_str="str"),
}

import os
from typing import Union

from fastapi import FastAPI


def environment_variable(name: str, default: str) -> str:
    return os.environ[name] if name in os.environ else default


def magic_function(x: int, y: int) -> int:
    sum = x + y
    if sum == 42:
        return 0
    else:
        return sum


ARCHETYPE_NAME = "ARCHETYPE_NAME"
configuration_value = environment_variable(ARCHETYPE_NAME, "NAMELESS!")
app = FastAPI()


@app.get("/")
def read_root():
    return {"Hello": configuration_value}


@app.get("/items/{item_id}")
def read_item(item_id: int, q: Union[str, None] = None):
    return {"item_id": item_id, "q": q}

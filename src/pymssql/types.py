"""Runtime type aliases for pymssql row and parameter types."""

from collections.abc import Mapping, Sequence
from datetime import date, datetime, time
from decimal import Decimal
from typing import Union
from uuid import UUID

SqlValue = Union[str, int, float, Decimal, bool, bytes, bytearray, datetime, date, time, UUID, None]
TupleRow = tuple[SqlValue, ...]
DictRow = dict[str, SqlValue]
QueryParams = Union[SqlValue, Sequence[Union[SqlValue, Sequence[SqlValue]]], Mapping[str, Union[SqlValue, Sequence[SqlValue]]]]

ColumnDescription = tuple[str, int, None, None, None, None, None]

__all__ = ["SqlValue", "TupleRow", "DictRow", "QueryParams", "ColumnDescription"]

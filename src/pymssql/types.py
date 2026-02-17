"""Runtime type aliases for pymssql.

These types mirror the definitions in the type stubs and can be imported at
runtime for use in type annotations. They describe the shapes of data returned
by pymssql query methods.

``SqlValue``
    Union of all scalar types that can appear in a result row.

``TupleRow``
    A row returned when ``as_dict=False`` (the default).

``DictRow``
    A row returned when ``as_dict=True``.

``QueryParams``
    Accepted parameter types for query execution methods
    (``execute``, ``executemany``, etc.).
"""

from collections.abc import Mapping
from datetime import date, datetime, time
from decimal import Decimal
from uuid import UUID

SqlValue = str | int | float | Decimal | bool | bytes | datetime | date | time | UUID | None
TupleRow = tuple[SqlValue, ...]
DictRow = dict[str, SqlValue]
QueryParams = SqlValue | tuple[SqlValue | tuple[SqlValue, ...], ...] | Mapping[str, SqlValue | tuple[SqlValue, ...]]

__all__ = ["SqlValue", "TupleRow", "DictRow", "QueryParams"]

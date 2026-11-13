"""Split SQL Server multipart names for bulk-copy catalog lookup."""

from __future__ import annotations


def bulk_copy_column_source(table_name: str) -> tuple[str, str]:
    """
    Return ``(columns_view, lookup_name)`` for a bulk-copy target.

    Temp tables live in tempdb. Outside tempdb, ``OBJECT_ID('#t')`` is NULL,
    and a tempdb object id does not appear in the current database's
    ``sys.columns``. The object is still a temp table when a schema or
    delimiters hide the leading ``#``, as in ``dbo.#t``, ``[dbo].[#t]``,
    ``"#t"``, or ``"dbo"."#t"``.
    """
    parts = _split_multipart_name(table_name)
    # A server-qualified name is not the local tempdb catalog, so only a
    # 3-part tempdb name counts as already qualified.
    local_tempdb = len(parts) == 3 and _unquote_identifier(parts[0]).lower() == "tempdb"
    is_temp = _unquote_identifier(parts[-1]).startswith("#")
    if is_temp or local_tempdb:
        columns_view = "tempdb.sys.columns"
    else:
        columns_view = "sys.columns"
    if is_temp and not local_tempdb:
        schema = parts[-2] if len(parts) > 1 else ""
        return columns_view, "tempdb." + schema + "." + parts[-1]
    return columns_view, table_name


def _split_multipart_name(name: str) -> list[str]:
    """Split on dots that are outside ``[]`` and ``""`` delimiters."""
    parts: list[str] = []
    buf: list[str] = []
    i = 0
    n = len(name)
    while i < n:
        ch = name[i]
        if ch == ".":
            parts.append("".join(buf))
            buf = []
            i += 1
            continue
        if ch in ("[", '"'):
            closer = "]" if ch == "[" else '"'
            buf.append(ch)
            i += 1
            while i < n:
                buf.append(name[i])
                if name[i] == closer:
                    if i + 1 < n and name[i + 1] == closer:
                        buf.append(name[i + 1])
                        i += 2
                        continue
                    i += 1
                    break
                i += 1
            continue
        buf.append(ch)
        i += 1
    parts.append("".join(buf))
    return parts


def _unquote_identifier(part: str) -> str:
    if len(part) >= 2 and part[0] == "[" and part[-1] == "]":
        return part[1:-1].replace("]]", "]")
    if len(part) >= 2 and part[0] == '"' and part[-1] == '"':
        return part[1:-1].replace('""', '"')
    return part

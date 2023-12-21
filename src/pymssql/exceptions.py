

# exception hierarchy
class Warning(Exception):
    pass

class Error(Exception):
    pass

class InterfaceError(Error):
    pass

class DatabaseError(Error):
    pass

class DataError(DatabaseError):
    pass

class OperationalError(DatabaseError):
    pass

class IntegrityError(DatabaseError):
    pass

class InternalError(DatabaseError):
    pass

class ProgrammingError(DatabaseError):
    pass

class NotSupportedError(DatabaseError):
    pass

class ColumnsWithoutNamesError(InterfaceError):
    def __init__(self, columns_without_names):
        self.columns_without_names = columns_without_names

    def __str__(self):
        return 'Specified as_dict=True and ' \
            'there are columns with no names: %r' \
            % (self.columns_without_names,)

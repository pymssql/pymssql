# -*- coding: utf-8 -*-

import socket
import struct
import threading
import time

import pytest
import pymssql


def _tds_packet(body):
    return struct.pack(">BBHHBB", 0x04, 0x01, len(body) + 8, 0, 1, 0) + body


def _prelogin_response():
    options = [(0x00, b"\x0f\x00\x0b\xb8\x00\x00"), (0x01, b"\x02")]
    header, data = b"", b""
    offset = 5 * len(options) + 1
    for token, payload in options:
        header += struct.pack(">BHH", token, offset, len(payload))
        offset += len(payload)
        data += payload
    return _tds_packet(header + b"\xff" + data)


def _login_response(tds_version):
    name = "tds-stub".encode("utf-16-le")
    login_ack = (
        b"\x01" + tds_version[::-1] + bytes([len(name) // 2]) + name
        + b"\x10\x00\x00\x00"
    )
    env = "4096".encode("utf-16-le")
    env_change = (
        b"\x04" + bytes([len(env) // 2]) + env
        + bytes([len(env) // 2]) + env
    )
    done = b"\xfd" + struct.pack("<HHQ", 0, 0, 0)
    return _tds_packet(
        b"\xad" + struct.pack("<H", len(login_ack)) + login_ack
        + b"\xe3" + struct.pack("<H", len(env_change)) + env_change + done
    )


def _read_exact(sock, size):
    data = bytearray()
    while len(data) < size:
        chunk = sock.recv(size - len(data))
        if not chunk:
            raise ConnectionError("client disconnected")
        data.extend(chunk)
    return bytes(data)


class _TdsStub:
    def __init__(self):
        self._socket = socket.socket()
        self._socket.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
        self._socket.bind(("127.0.0.1", 0))
        self._socket.listen()
        self._socket.settimeout(0.2)
        self.port = self._socket.getsockname()[1]
        self._stopping = threading.Event()
        self._clients = []
        self._clients_lock = threading.Lock()
        self._thread = threading.Thread(target=self._serve, daemon=True)

    def __enter__(self):
        self._thread.start()
        return self

    def __exit__(self, *args):
        self._stopping.set()
        self._socket.close()
        self._thread.join(timeout=1)
        with self._clients_lock:
            for client in self._clients:
                client.close()

    def _serve(self):
        while not self._stopping.is_set():
            try:
                client, _ = self._socket.accept()
            except socket.timeout:
                continue
            except OSError:
                return
            with self._clients_lock:
                self._clients.append(client)
            threading.Thread(
                target=self._serve_client, args=(client,), daemon=True
            ).start()

    @staticmethod
    def _serve_client(client):
        client.settimeout(15)
        batches = 0
        try:
            while True:
                header = _read_exact(client, 8)
                packet_type = header[0]
                length = struct.unpack(">H", header[2:4])[0]
                body = _read_exact(client, length - 8)
                if packet_type == 0x12:
                    client.sendall(_prelogin_response())
                elif packet_type == 0x10:
                    client.sendall(_login_response(body[4:8]))
                elif packet_type == 0x01:
                    batches += 1
                    if batches == 1:
                        done = b"\xfd" + struct.pack("<HHQ", 0x0010, 0, 0)
                        client.sendall(_tds_packet(done))
                    # Leave the query batch unanswered to trigger its timeout.
        except (ConnectionError, OSError, TimeoutError):
            return


def _run_query(connection, errors):
    try:
        connection.cursor().execute("SELECT 1")
    except Exception as exc:
        errors.append(exc)


def test_query_timeout_does_not_deadlock_other_connections():
    with _TdsStub() as server:
        connection = pymssql.connect(
            server="127.0.0.1",
            port=server.port,
            user="sa",
            password="test",
            login_timeout=5,
            timeout=1,
            autocommit=True,
        )
        query_errors = []
        query_thread = threading.Thread(
            target=_run_query, args=(connection, query_errors), daemon=True
        )
        query_thread.start()
        query_thread.join(timeout=5)

        second_connections = []
        connect_errors = []

        def reconnect():
            try:
                second_connections.append(
                    pymssql.connect(
                        server="127.0.0.1",
                        port=server.port,
                        user="sa",
                        password="test",
                        login_timeout=5,
                        timeout=1,
                        autocommit=True,
                    )
                )
            except Exception as exc:
                connect_errors.append(exc)

        connect_thread = threading.Thread(target=reconnect, daemon=True)
        connect_thread.start()
        connect_thread.join(timeout=5)

        try:
            assert not query_thread.is_alive(), "query timeout left the thread blocked"
            assert query_errors and isinstance(query_errors[0], pymssql.OperationalError)
            assert not connect_thread.is_alive(), "a later connect() was blocked"
            assert not connect_errors
            assert len(second_connections) == 1
        finally:
            if not query_thread.is_alive():
                connection.close()
            for second in second_connections:
                second.close()


@pytest.mark.slow
@pytest.mark.mssql_server_required
@pytest.mark.timeout(120)
@pytest.mark.xfail(strict=False)
@pytest.mark.parametrize('to', [2])
def test_remote_connect_timeout(to):

    t = time.time()
    try:
        pymssql.connect(server="www.google.com", port=81, user='username', password='password',
                            login_timeout=to)
    except pymssql.OperationalError:
        pass
    t = time.time() - t
    print('remote: requested {} -> {} actual timeout'.format(to, t))
    assert t == pytest.approx(to, 5), "{} != {}".format(t, to)

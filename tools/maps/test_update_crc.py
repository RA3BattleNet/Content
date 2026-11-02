"""Run with python -B -m unittest discover -s tools/maps -p 'test_*.py'."""

import contextlib
import io
from pathlib import Path
import tempfile
import unittest

import update_crc


class MapCrcTests(unittest.TestCase):
    def setUp(self):
        self.directory = tempfile.TemporaryDirectory()
        self.addCleanup(self.directory.cleanup)
        self.root = Path(self.directory.name)
        self.metadata = self.root / "Data/additionalmaps/mapmetadata_test.xml"
        self.metadata.parent.mkdir(parents=True)
        self.map_path = self.root / "Additional/Data/maps/official/Test_Map/Test_Map.map"
        self.map_path.parent.mkdir(parents=True)
        self.map_path.write_bytes(b"abc")

    def document(self, attributes='CRC="0"', extra=b""):
        data = (b'\xef\xbb\xbf<?xml version="1.0" encoding="utf-8"?>\r\n'
                b'<AssetDeclaration xmlns="uri:ea.com:eala:asset">\r\n'
                b'<!-- <MapMetaData CRC="0" FileName="not_a_map" /> -->\r\n'
                b'<MapMetaData id="Cache"><MapMetaData Description="a > b" '
                + attributes.encode("ascii")
                + b' FileName="data\\maps\\official\\test_map\\test_map.map" />'
                + extra + b'</MapMetaData>\r\n</AssetDeclaration>\r\n')
        self.metadata.write_bytes(data)
        return data

    def run_update(self, write=False):
        with contextlib.redirect_stdout(io.StringIO()):
            return update_crc.update(self.root, write)

    def test_checksum_unsigned_wrap_and_block_boundary(self):
        for data, expected in ((b"", 0), (b"abc", 683), (b"\xff\xff", 765),
                               (b"\x80" + b"\0" * 25, 1),
                               (b"\x01" + b"\0" * 4096, 1)):
            with self.subTest(length=len(data), expected=expected):
                self.map_path.write_bytes(data)
                self.assertEqual(update_crc.map_crc(self.map_path), expected)

    def test_check_write_and_idempotence_preserve_original_bytes(self):
        original = self.document()
        self.assertEqual(self.run_update(), 1)
        self.assertEqual(self.metadata.read_bytes(), original)
        self.assertEqual(self.run_update(True), 0)
        expected = original.replace(b'Description="a > b" CRC="0"',
                                    b'Description="a > b" CRC="683"')
        self.assertEqual(self.metadata.read_bytes(), expected)
        before = self.metadata.stat().st_mtime_ns
        self.assertEqual(self.run_update(), 0)
        self.assertEqual(self.run_update(True), 0)
        self.assertEqual(self.metadata.stat().st_mtime_ns, before)

    def test_missing_crc_and_single_quoted_crc(self):
        for attribute in ("", "CRC='0'"):
            with self.subTest(attribute=attribute):
                self.document(attribute)
                self.assertEqual(self.run_update(True), 0)
                self.assertEqual(self.run_update(), 0)

    def test_duplicate_registration_in_another_pool(self):
        self.document()
        other = self.metadata.with_name("mapmetadata_other.xml")
        other.write_bytes(self.metadata.read_bytes())
        self.assertEqual(self.run_update(True), 0)
        self.assertEqual(other.read_bytes(), self.metadata.read_bytes())

    def test_missing_map_rejects_before_any_write(self):
        original = self.document()
        other = self.metadata.with_name("mapmetadata_z_missing.xml")
        other.write_bytes(original.replace(b"test_map.map", b"missing.map"))
        with self.assertRaisesRegex(ValueError, "map file not found"):
            self.run_update(True)
        self.assertEqual(self.metadata.read_bytes(), original)

    def test_unregistered_map_is_reported(self):
        original = self.document()
        self.map_path.with_name("Forgotten.map").write_bytes(b"abc")
        with self.assertRaisesRegex(ValueError, "no MapMetaData entry"):
            self.run_update(True)
        self.assertEqual(self.metadata.read_bytes(), original)


if __name__ == "__main__":
    unittest.main()

"""Build the small native plugin that exposes Dreamforged's chargen classes."""

from pathlib import Path
import struct

ROOT = Path(__file__).resolve().parents[1]
OUTPUT = ROOT / "AshenLoot-Classes.esp"
MASTER = Path(r"F:\Morrowind Data Files\Data Files\Morrowind.esm")


def subrecord(name: str, data: bytes) -> bytes:
    return name.encode("ascii") + struct.pack("<I", len(data)) + data


def ztext(value: str) -> bytes:
    return value.encode("cp1252") + b"\0"


def record(name: str, body: bytes) -> bytes:
    return name.encode("ascii") + struct.pack("<III", len(body), 0, 0) + body


# id, display name, description, attributes, specialization,
# five (minor, major) skill pairs. Skill numbers are Morrowind's native IDs.
CLASSES = [
    ("AL_Warrior", "Dreamforged Warrior",
     "A heavily specialized front-line fighter built to hold ground against larger enemy groups. Warriors excel at armored melee but receive no help outside their martial toolkit.",
     (0, 5), 0, [(6, 5), (4, 0), (7, 3), (2, 1), (23, 8)]),
    ("AL_WarMage", "Dreamforged War Mage",
     "An armored combat caster for dangerous, enemy-rich ruins. War Mages combine direct destruction and healing with heavy protection, enchantment, and a crushing backup weapon.",
     (1, 5), 1, [(11, 10), (14, 15), (13, 3), (0, 4), (16, 9)]),
    ("AL_Archer", "Dreamforged Archer",
     "A dedicated ranged combatant who controls crowded fights through accuracy, movement, and positioning. Archers remain capable when enemies close, but ranged pressure is their defining strength.",
     (3, 4), 0, [(20, 23), (22, 21), (16, 8), (18, 19), (15, 7)]),
    ("AL_Rogue", "Dreamforged Rogue",
     "A focused infiltrator who isolates threats and strikes vulnerable targets. Rogues excel at stealth, access, evasion, and short blades rather than prolonged stand-up fighting.",
     (3, 4), 2, [(23, 22), (20, 19), (25, 21), (24, 18), (16, 12)]),
    ("AL_Conjurer", "Dreamforged Conjurer",
     "A pure magical controller who survives groups through summons, illusion, wards, and supernatural utility. Conjurers gain broad magical mastery but no conventional armor training.",
     (1, 2), 1, [(15, 13), (10, 12), (16, 14), (17, 11), (22, 9)]),
]


def class_record(entry) -> bytes:
    ident, name, description, attrs, spec, pairs = entry
    values = [attrs[0], attrs[1], spec]
    for minor, major in pairs:
        values.extend((minor, major))
    values.extend((1, 0))  # playable, services
    body = b"".join((
        subrecord("NAME", ztext(ident)),
        subrecord("FNAM", ztext(name)),
        subrecord("CLDT", struct.pack("<15i", *values)),
        subrecord("DESC", ztext(description)),
    ))
    return record("CLAS", body)


def main() -> None:
    author = b"Morrowind: Dreamforged".ljust(32, b"\0")
    description = b"Five level-one archetypes for Dreamforged's denser encounters.".ljust(256, b"\0")
    hedr = struct.pack("<fI", 1.3, 0) + author + description + struct.pack("<I", len(CLASSES))
    header = subrecord("HEDR", hedr)
    header += subrecord("MAST", ztext("Morrowind.esm"))
    header += subrecord("DATA", struct.pack("<Q", MASTER.stat().st_size))
    OUTPUT.write_bytes(record("TES3", header) + b"".join(map(class_record, CLASSES)))
    print(f"Wrote {OUTPUT} ({OUTPUT.stat().st_size} bytes)")


if __name__ == "__main__":
    main()

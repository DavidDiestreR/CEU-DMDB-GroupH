"""
Generate course.csv and program-course associative table CSVs
from data/private/to_be_implemented.csv.

Outputs go to data/public/real_data/.
Also produces department/term/program mapping files for teammates.

Usage:  python data_preprocessing/generate_csvs.py
"""

import csv
import os
import re
from collections import OrderedDict

BASE_DIR = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SOURCE = os.path.join(BASE_DIR, "data", "private", "to_be_implemented.csv")
OUT_DIR = os.path.join(BASE_DIR, "data", "public", "real_data")

os.makedirs(OUT_DIR, exist_ok=True)


# ---------------------------------------------------------------------------
# 1. Read source CSV, skip rows with empty course_code
# ---------------------------------------------------------------------------
def read_source():
    with open(SOURCE, encoding="utf-8") as f:
        reader = csv.DictReader(f)
        rows = [r for r in reader if r["course_code"].strip()]
    print(f"Read {len(rows)} valid rows (non-empty course_code)")
    return rows


# ---------------------------------------------------------------------------
# 2. Build ID mappings for departments, terms, programs
# ---------------------------------------------------------------------------
def build_department_map(rows):
    names = sorted({r["Department"].strip() for r in rows if r["Department"].strip()})
    return {name: i + 1 for i, name in enumerate(names)}


def normalize_term(raw):
    """Pick the first simple term from multi-term strings."""
    raw = raw.strip()
    if not raw:
        return ""
    # Canonical simple terms
    simple = ["Fall term", "Winter term", "Spring term", "Pre-session"]
    for s in simple:
        if s.lower() in raw.lower():
            return s
    return raw


def build_term_map(rows):
    """Build term_id mapping. We extract unique normalized term names."""
    raw_terms = {r["term"].strip() for r in rows if r["term"].strip()}
    # Map each raw term to its normalized form
    norm_set = sorted({normalize_term(t) for t in raw_terms if normalize_term(t)})
    return {name: i + 1 for i, name in enumerate(norm_set)}


def build_program_map(rows):
    names = sorted({r["Corresponding_program"].strip() for r in rows
                     if r["Corresponding_program"].strip()})
    return {name: i + 1 for i, name in enumerate(names)}


# ---------------------------------------------------------------------------
# 3. Deduplicate courses (one row per course_code, take first occurrence)
# ---------------------------------------------------------------------------
def deduplicate_courses(rows):
    seen = OrderedDict()
    for r in rows:
        code = r["course_code"].strip()
        if code and code not in seen:
            seen[code] = r
    return list(seen.values())


# ---------------------------------------------------------------------------
# 4. Map a source row to a course CSV row
# ---------------------------------------------------------------------------
def to_bool(val):
    return "true" if val.strip().lower() == "yes" else "false"


def safe_int(val, default=1):
    try:
        return int(float(val))
    except (ValueError, TypeError):
        return default


def make_course_row(row, course_id, dept_map, term_map):
    dept_name = row["Department"].strip()
    department_id = dept_map.get(dept_name, "")

    raw_term = row["term"].strip()
    norm = normalize_term(raw_term)
    # Default to Fall term if source has no term (term_id is NOT NULL)
    term_id = term_map.get(norm, term_map.get("Fall term", 1))

    return {
        "course_id": course_id,
        "course_code": row["course_code"].strip(),
        "course_name": row["course_name"].strip(),
        "us_credits": safe_int(row["US_credits"], 2),
        "ects_credits": safe_int(row["ECTS"], 4),
        "department_id": department_id,
        "term_id": term_id,
        "course_description": row.get("Background_and_overall_aim", "").strip(),
        "prereq_text": row.get("Course_prerequisites", "").strip(),
        "course_learning_outcomes": row.get("Learning_outcomes", "").strip(),
        "excludes_course_id": "",
        "level": row["Level"].strip(),
        "abbreviation": row["Abbreviation"].strip(),
        "course_type": row["Course_type"].strip(),
        "marking_scheme": row["Marking_scheme"].strip(),
        "offered_for_non_degree_students": to_bool(row.get("Offered_for_non_degree_students", "No")),
        "allow_repeats": to_bool(row.get("allow_repeats", "No")),
        "scheme": row.get("Scheme", "").strip(),
        "learning_activities_and_teaching_methods": row.get("Learning_activities_and_teaching_methods", "").strip(),
        "assessment": row.get("Assessment", "").strip(),
        "course_contents": row.get("Course_contents", "").strip(),
        "background_and_overall_aim": row.get("Background_and_overall_aim", "").strip(),
        "contact_details": row.get("Contact_details", "").strip(),
    }


# ---------------------------------------------------------------------------
# 5. Determine relationship type from Corresponding_collections
# ---------------------------------------------------------------------------
YEAR_RE = re.compile(r"(\d+)(?:st|nd|rd|th)\s+year", re.IGNORECASE)


def classify_collection_label(label):
    """Return (type, year) from a single collection label.
    type is one of: 'mandatory', 'elective', 'mandatory_elective', or None.
    """
    low = label.lower().strip()
    year = 1
    m = YEAR_RE.search(low)
    if m:
        year = int(m.group(1))

    # Order matters: check "mandatory elective" before "mandatory" or "elective"
    if "mandatory elective" in low or "mandatory_elective" in low:
        return ("mandatory_elective", year)
    elif "mandatory" in low and "elective" not in low:
        return ("mandatory", year)
    elif "elective" in low:
        return ("elective", year)
    return (None, year)


def determine_relationship(row, program_name):
    """For a given row+program, determine the relationship type and year.

    Strategy:
    1. Parse all collection labels
    2. Try to find one that relates to this program
    3. Fall back to the most specific match
    """
    collections_str = row.get("Corresponding_collections", "")
    labels = [l.strip() for l in collections_str.split(",") if l.strip()]

    # Collect all classified labels
    candidates = []
    for label in labels:
        rel_type, year = classify_collection_label(label)
        if rel_type:
            candidates.append((rel_type, year, label))

    if not candidates:
        # No classifiable label found - default to elective
        return ("elective", 1)

    # If only one type found, use it
    types_found = {c[0] for c in candidates}
    if len(types_found) == 1:
        # Use the year from the first match
        return (candidates[0][0], candidates[0][1])

    # Multiple types - try to match program name keywords to label
    # e.g., program "PhD in Economics" should match label "Economics PhD 1st year mandatory"
    prog_words = set(program_name.lower().split())
    best = None
    best_score = -1
    for rel_type, year, label in candidates:
        label_words = set(label.lower().split())
        score = len(prog_words & label_words)
        if score > best_score:
            best_score = score
            best = (rel_type, year)

    return best if best else (candidates[0][0], candidates[0][1])


# ---------------------------------------------------------------------------
# 6. Build associative tables
# ---------------------------------------------------------------------------
def build_associative_tables(rows, course_id_map, program_map):
    """Return three dicts: mandatory, elective, mandatory_elective.
    Each is a dict of (program_id, course_id) -> available_from_year_n.
    """
    mandatory = {}
    elective = {}
    mandatory_elective = {}

    table_map = {
        "mandatory": mandatory,
        "elective": elective,
        "mandatory_elective": mandatory_elective,
    }

    for r in rows:
        code = r["course_code"].strip()
        prog = r["Corresponding_program"].strip()
        if not code or not prog:
            continue
        if code not in course_id_map or prog not in program_map:
            continue

        course_id = course_id_map[code]
        program_id = program_map[prog]
        key = (program_id, course_id)

        rel_type, year = determine_relationship(r, prog)
        table = table_map[rel_type]

        # Only keep first occurrence (dedup)
        if key not in table:
            table[key] = year

    return mandatory, elective, mandatory_elective


# ---------------------------------------------------------------------------
# 7. Write CSV files
# ---------------------------------------------------------------------------
def write_csv(path, fieldnames, rows):
    with open(path, "w", newline="", encoding="utf-8") as f:
        writer = csv.DictWriter(f, fieldnames=fieldnames)
        writer.writeheader()
        writer.writerows(rows)
    print(f"  Wrote {path} ({len(rows)} rows)")


def write_assoc_csv(path, data):
    """Write an associative table CSV from a {(prog_id, course_id): year} dict."""
    rows = [
        {"program_id": k[0], "course_id": k[1], "available_from_year_n": v}
        for k, v in sorted(data.items())
    ]
    write_csv(path, ["program_id", "course_id", "available_from_year_n"], rows)


# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------
def main():
    rows = read_source()

    # Build mappings
    dept_map = build_department_map(rows)
    term_map = build_term_map(rows)
    prog_map = build_program_map(rows)

    print(f"\nMappings: {len(dept_map)} departments, {len(term_map)} terms, {len(prog_map)} programs")

    # Deduplicate courses
    unique_courses = deduplicate_courses(rows)
    print(f"Unique courses: {len(unique_courses)}\n")

    # Build course_code -> course_id mapping (sorted by code)
    sorted_codes = sorted(r["course_code"].strip() for r in unique_courses)
    code_to_id = {code: i + 1 for i, code in enumerate(sorted_codes)}

    # Generate course rows
    course_fields = [
        "course_id", "course_code", "course_name", "us_credits", "ects_credits",
        "department_id", "term_id", "course_description", "prereq_text",
        "course_learning_outcomes", "excludes_course_id", "level", "abbreviation",
        "course_type", "marking_scheme", "offered_for_non_degree_students",
        "allow_repeats", "scheme", "learning_activities_and_teaching_methods",
        "assessment", "course_contents", "background_and_overall_aim", "contact_details",
    ]

    course_rows = []
    for r in unique_courses:
        cid = code_to_id[r["course_code"].strip()]
        course_rows.append(make_course_row(r, cid, dept_map, term_map))

    # Sort by course_id
    course_rows.sort(key=lambda x: x["course_id"])

    # Build associative tables
    mandatory, elective, mand_elective = build_associative_tables(
        rows, code_to_id, prog_map
    )

    # Write all output files
    print("Writing output files:")
    write_csv(os.path.join(OUT_DIR, "course.csv"), course_fields, course_rows)
    write_assoc_csv(os.path.join(OUT_DIR, "program_mandatory_course.csv"), mandatory)
    write_assoc_csv(os.path.join(OUT_DIR, "program_elective_course.csv"), elective)
    write_assoc_csv(os.path.join(OUT_DIR, "program_mandatory_elective_course.csv"), mand_elective)

    # Write mapping files for teammates
    dept_rows = [{"department_id": v, "department_name": k} for k, v in sorted(dept_map.items(), key=lambda x: x[1])]
    write_csv(os.path.join(OUT_DIR, "department_mapping.csv"), ["department_id", "department_name"], dept_rows)

    term_rows = [{"term_id": v, "term_name": k} for k, v in sorted(term_map.items(), key=lambda x: x[1])]
    write_csv(os.path.join(OUT_DIR, "term_mapping.csv"), ["term_id", "term_name"], term_rows)

    prog_rows = [{"program_id": v, "program_name": k} for k, v in sorted(prog_map.items(), key=lambda x: x[1])]
    write_csv(os.path.join(OUT_DIR, "program_mapping.csv"), ["program_id", "program_name"], prog_rows)

    # Summary
    print(f"\nSummary:")
    print(f"  Courses:             {len(course_rows)}")
    print(f"  Mandatory pairs:     {len(mandatory)}")
    print(f"  Elective pairs:      {len(elective)}")
    print(f"  Mand. elective pairs:{len(mand_elective)}")
    print(f"\nDone! Files in {OUT_DIR}")


if __name__ == "__main__":
    main()

/*
  Analytical query: top 5 universities by student count within each parent place (e.g., country).
  Joins:
    - person_study_at_university.university_id = organisation.id
    - organisation.location_place_id = place.id (university location)
    - place.part_of_place_id = parent_place.id (hierarchical place)
  Aggregates student counts per university, then ranks within each parent place.
*/
WITH uni_students AS (
    SELECT
        org.id AS university_id,
        org.name AS university_name,
        org.type AS university_type,
        org.url AS university_url,
        org.location_place_id,
        COUNT(DISTINCT psu.person_id) AS student_count
    FROM person_study_at_university psu
    JOIN organisation org
        ON psu.university_id = org.id
    GROUP BY
        org.id,
        org.name,
        org.type,
        org.url,
        org.location_place_id
),
uni_location AS (
    SELECT
        us.university_id,
        us.university_name,
        us.student_count,
        loc.id AS location_id,
        loc.name AS location_name,
        loc.type AS location_type,
        parent.id AS parent_location_id,
        parent.name AS parent_location_name,
        parent.type AS parent_location_type
    FROM uni_students us
    JOIN place loc
        ON us.location_place_id = loc.id
    LEFT JOIN place parent
        ON loc.part_of_place_id = parent.id
),
ranked_universities AS (
    SELECT
        university_id,
        university_name,
        location_name,
        parent_location_name,
        student_count,
        RANK() OVER (PARTITION BY parent_location_name ORDER BY student_count DESC) AS rank_within_parent
    FROM uni_location
)
SELECT
    university_name,
    location_name,
    parent_location_name,
    student_count,
    rank_within_parent
FROM ranked_universities
WHERE rank_within_parent <= 5
ORDER BY parent_location_name, rank_within_parent

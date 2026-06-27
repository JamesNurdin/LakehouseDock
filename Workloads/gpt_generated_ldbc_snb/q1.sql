WITH uni_stats AS (
    SELECT
        o.id,
        o.name,
        o."type",
        o.location_place_id,
        COUNT(ps.person_id) AS num_students,
        COUNT(DISTINCT ps.person_id) AS distinct_students,
        AVG(ps.class_year) AS avg_class_year,
        MIN(ps.creation_date) AS earliest_study_date,
        MAX(ps.creation_date) AS latest_study_date
    FROM organisation AS o
    JOIN person_study_at_university AS ps
        ON ps.university_id = o.id
    GROUP BY
        o.id,
        o.name,
        o."type",
        o.location_place_id
)
SELECT
    id,
    name,
    "type",
    location_place_id,
    num_students,
    distinct_students,
    avg_class_year,
    earliest_study_date,
    latest_study_date
FROM uni_stats
ORDER BY num_students DESC
LIMIT 10

WITH person_cast_counts AS (
    SELECT
        ci.person_id,
        COUNT(*) AS cast_entries,
        COUNT(DISTINCT ci.movie_id) AS distinct_movies,
        MIN(ci.role_id) AS min_role_id,
        MAX(ci.role_id) AS max_role_id
    FROM cast_info ci
    GROUP BY ci.person_id
),
person_aka_names AS (
    SELECT
        an.person_id,
        COUNT(*) AS aka_name_count,
        ARRAY_AGG(an.name) AS aka_names
    FROM aka_name an
    GROUP BY an.person_id
)
SELECT
    n.id,
    n.name,
    n.gender,
    COALESCE(pc.cast_entries, 0) AS total_cast_entries,
    COALESCE(pc.distinct_movies, 0) AS total_distinct_movies,
    COALESCE(pan.aka_name_count, 0) AS total_aka_names,
    pan.aka_names
FROM name n
LEFT JOIN person_cast_counts pc
    ON pc.person_id = n.id
LEFT JOIN person_aka_names pan
    ON pan.person_id = n.id
WHERE n.gender = 'M'
ORDER BY total_distinct_movies DESC
LIMIT 100

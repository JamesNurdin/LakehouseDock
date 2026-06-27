WITH person_movies AS (
    SELECT
        ci.person_id,
        COUNT(DISTINCT ci.movie_id) AS total_movies,
        MIN(t.production_year) AS earliest_production_year,
        MAX(t.production_year) AS latest_production_year,
        AVG(ci.nr_order) AS average_cast_order
    FROM cast_info ci
    JOIN title t ON ci.movie_id = t.id
    GROUP BY ci.person_id
),
person_alternate_names AS (
    SELECT
        an.person_id,
        COUNT(DISTINCT an.id) AS alternate_name_count
    FROM aka_name an
    GROUP BY an.person_id
),
person_movie_info_types AS (
    SELECT
        sub.person_id,
        COUNT(DISTINCT sub.info_type_id) AS distinct_movie_info_type_count
    FROM (
        SELECT ci.person_id, mi.info_type_id
        FROM cast_info ci
        JOIN title t ON ci.movie_id = t.id
        JOIN movie_info mi ON mi.movie_id = t.id
        UNION ALL
        SELECT ci.person_id, mi_idx.info_type_id
        FROM cast_info ci
        JOIN title t ON ci.movie_id = t.id
        JOIN movie_info_idx mi_idx ON mi_idx.movie_id = t.id
    ) sub
    GROUP BY sub.person_id
),
person_person_info_counts AS (
    SELECT
        pi.person_id,
        COUNT(DISTINCT pi.id) AS person_info_count
    FROM person_info pi
    GROUP BY pi.person_id
)
SELECT
    n.id AS person_id,
    n.name AS person_name,
    COALESCE(pm.total_movies, 0) AS total_movies,
    pm.earliest_production_year,
    pm.latest_production_year,
    pm.average_cast_order,
    COALESCE(pan.alternate_name_count, 0) AS alternate_name_count,
    COALESCE(pmitc.distinct_movie_info_type_count, 0) AS distinct_movie_info_type_count,
    COALESCE(ppic.person_info_count, 0) AS person_info_count
FROM name n
LEFT JOIN person_movies pm ON pm.person_id = n.id
LEFT JOIN person_alternate_names pan ON pan.person_id = n.id
LEFT JOIN person_movie_info_types pmitc ON pmitc.person_id = n.id
LEFT JOIN person_person_info_counts ppic ON ppic.person_id = n.id
ORDER BY total_movies DESC, person_name
LIMIT 10

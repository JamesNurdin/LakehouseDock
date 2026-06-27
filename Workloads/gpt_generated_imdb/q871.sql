WITH actor_movies AS (
    SELECT
        ci.person_id,
        n.name AS person_name,
        n.gender,
        ci.movie_id,
        t.id AS title_id,
        t.production_year
    FROM cast_info ci
    JOIN name n ON ci.person_id = n.id
    JOIN title t ON ci.movie_id = t.id
    WHERE t.production_year > 2000
),
person_alternate_names AS (
    SELECT
        an.person_id,
        COUNT(DISTINCT an.id) AS alt_name_count
    FROM aka_name an
    GROUP BY an.person_id
),
person_info_counts AS (
    SELECT
        pi.person_id,
        COUNT(DISTINCT pi.info_type_id) AS info_type_count
    FROM person_info pi
    GROUP BY pi.person_id
)
SELECT
    am.person_id,
    am.person_name,
    am.gender,
    COUNT(DISTINCT am.title_id) AS movies_after_2000,
    COALESCE(pan.alt_name_count, 0) AS alt_name_count,
    COALESCE(pic.info_type_count, 0) AS info_type_count
FROM actor_movies am
LEFT JOIN person_alternate_names pan ON pan.person_id = am.person_id
LEFT JOIN person_info_counts pic ON pic.person_id = am.person_id
GROUP BY
    am.person_id,
    am.person_name,
    am.gender,
    pan.alt_name_count,
    pic.info_type_count
ORDER BY movies_after_2000 DESC, am.person_name
LIMIT 100

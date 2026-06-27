WITH person_movies AS (
    SELECT
        n.id AS person_id,
        n.name AS person_name,
        n.gender,
        t.id AS movie_id,
        t.title AS movie_title,
        t.production_year,
        ci.role_id,
        ci.person_role_id AS char_id,
        cn.name AS character_name
    FROM cast_info ci
    JOIN name n ON ci.person_id = n.id
    JOIN title t ON ci.movie_id = t.id
    LEFT JOIN char_name cn ON ci.person_role_id = cn.id
    WHERE t.production_year BETWEEN 2010 AND 2020
),
person_aka AS (
    SELECT
        n.id AS person_id,
        COUNT(DISTINCT ak.id) AS aka_count
    FROM name n
    LEFT JOIN aka_name ak ON ak.person_id = n.id
    GROUP BY n.id
),
person_info_counts AS (
    SELECT
        n.id AS person_id,
        COUNT(DISTINCT pi.id) AS info_count
    FROM name n
    LEFT JOIN person_info pi ON pi.person_id = n.id
    GROUP BY n.id
),
person_keywords AS (
    SELECT
        n.id AS person_id,
        COUNT(DISTINCT mk.keyword_id) AS keyword_count
    FROM name n
    JOIN cast_info ci ON ci.person_id = n.id
    JOIN title t ON ci.movie_id = t.id
    JOIN movie_keyword mk ON mk.movie_id = t.id
    WHERE t.production_year BETWEEN 2010 AND 2020
    GROUP BY n.id
)
SELECT
    pm.person_id,
    pm.person_name,
    pm.gender,
    COUNT(DISTINCT pm.movie_id) AS movie_count,
    COUNT(DISTINCT pm.char_id) AS distinct_role_count,
    COALESCE(pa.aka_count, 0) AS alternate_name_count,
    COALESCE(pic.info_count, 0) AS person_info_count,
    COALESCE(pk.keyword_count, 0) AS distinct_keyword_count
FROM person_movies pm
LEFT JOIN person_aka pa ON pa.person_id = pm.person_id
LEFT JOIN person_info_counts pic ON pic.person_id = pm.person_id
LEFT JOIN person_keywords pk ON pk.person_id = pm.person_id
GROUP BY
    pm.person_id,
    pm.person_name,
    pm.gender,
    pa.aka_count,
    pic.info_count,
    pk.keyword_count
ORDER BY movie_count DESC
LIMIT 20

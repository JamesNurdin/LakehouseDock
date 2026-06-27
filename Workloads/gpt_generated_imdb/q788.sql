WITH person_movies AS (
    SELECT
        n.id AS person_id,
        n.name AS person_name,
        n.gender AS gender,
        t.id AS movie_id,
        t.title AS movie_title,
        t.production_year,
        cn.role_id,
        cn.nr_order,
        cn.note AS cast_note,
        ch.name AS character_name
    FROM name n
    JOIN cast_info cn ON cn.person_id = n.id
    JOIN title t ON cn.movie_id = t.id
    LEFT JOIN char_name ch ON cn.person_role_id = ch.id
),
person_agg AS (
    SELECT
        pm.person_id,
        pm.person_name,
        pm.gender,
        COUNT(DISTINCT pm.movie_id) AS total_movies,
        COUNT(DISTINCT pm.role_id) AS total_roles,
        COUNT(DISTINCT mk.keyword_id) AS total_keywords,
        COUNT(DISTINCT mc.company_id) AS total_companies,
        MIN(pm.production_year) AS earliest_year,
        MAX(pm.production_year) AS latest_year
    FROM person_movies pm
    LEFT JOIN movie_keyword mk ON mk.movie_id = pm.movie_id
    LEFT JOIN movie_companies mc ON mc.movie_id = pm.movie_id
    GROUP BY pm.person_id, pm.person_name, pm.gender
),
aka_agg AS (
    SELECT
        an.person_id,
        array_agg(DISTINCT an.name) AS aka_names
    FROM aka_name an
    GROUP BY an.person_id
),
info_agg AS (
    SELECT
        pi.person_id,
        array_agg(DISTINCT pi.info) AS person_infos
    FROM person_info pi
    GROUP BY pi.person_id
)
SELECT
    pa.person_id,
    pa.person_name,
    pa.gender,
    pa.total_movies,
    pa.total_roles,
    pa.total_keywords,
    pa.total_companies,
    pa.earliest_year,
    pa.latest_year,
    aka.aka_names,
    info.person_infos
FROM person_agg pa
LEFT JOIN aka_agg aka ON aka.person_id = pa.person_id
LEFT JOIN info_agg info ON info.person_id = pa.person_id
ORDER BY pa.total_movies DESC
LIMIT 50

WITH movie_agg AS (
    SELECT
        it.id AS info_type_id,
        it.info AS info_type,
        COUNT(DISTINCT mi.movie_id) AS movie_cnt,
        AVG(t.production_year) AS avg_prod_year,
        AVG(LENGTH(mi.note)) AS avg_movie_note_len
    FROM title t
    JOIN movie_info mi
        ON mi.movie_id = t.id
    JOIN info_type it
        ON it.id = mi.info_type_id
    WHERE t.production_year >= 2000
    GROUP BY it.id, it.info
),
person_agg AS (
    SELECT
        it.id AS info_type_id,
        it.info AS info_type,
        COUNT(DISTINCT pi.person_id) AS person_cnt,
        AVG(LENGTH(pi.note)) AS avg_person_note_len
    FROM person_info pi
    JOIN info_type it
        ON it.id = pi.info_type_id
    GROUP BY it.id, it.info
)
SELECT
    m.info_type,
    m.movie_cnt,
    m.avg_prod_year,
    m.avg_movie_note_len,
    p.person_cnt,
    p.avg_person_note_len
FROM movie_agg m
LEFT JOIN person_agg p
    ON p.info_type_id = m.info_type_id
ORDER BY m.movie_cnt DESC
LIMIT 15

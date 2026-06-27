WITH movie_agg AS (
    SELECT
        it.id AS info_type_id,
        it.info AS info_type_name,
        COUNT(DISTINCT mi.movie_id) AS movie_count,
        AVG(mi.note) AS avg_movie_note
    FROM movie_info_idx mi
    JOIN info_type it
        ON mi.info_type_id = it.id
    GROUP BY it.id, it.info
),
person_agg AS (
    SELECT
        it.id AS info_type_id,
        it.info AS info_type_name,
        COUNT(DISTINCT pi.person_id) AS person_count,
        COUNT(CASE WHEN n.gender = 'M' THEN 1 END) AS male_persons,
        COUNT(CASE WHEN n.gender = 'F' THEN 1 END) AS female_persons
    FROM person_info pi
    JOIN info_type it
        ON pi.info_type_id = it.id
    JOIN name n
        ON pi.person_id = n.id
    GROUP BY it.id, it.info
)
SELECT
    COALESCE(m.info_type_id, p.info_type_id) AS info_type_id,
    COALESCE(m.info_type_name, p.info_type_name) AS info_type_name,
    COALESCE(m.movie_count, 0) AS movie_count,
    m.avg_movie_note,
    COALESCE(p.person_count, 0) AS person_count,
    COALESCE(p.male_persons, 0) AS male_persons,
    COALESCE(p.female_persons, 0) AS female_persons
FROM movie_agg m
FULL OUTER JOIN person_agg p
    ON m.info_type_id = p.info_type_id
ORDER BY info_type_id

WITH movie_info_agg AS (
    SELECT
        mi.info_type_id,
        COUNT(DISTINCT mi.movie_id) AS movie_cnt,
        AVG(LENGTH(mi.note)) AS avg_note_len
    FROM movie_info mi
    JOIN title t
        ON mi.movie_id = t.id
    WHERE t.production_year >= 2000
    GROUP BY mi.info_type_id
),
person_info_agg AS (
    SELECT
        pi.info_type_id,
        COUNT(DISTINCT pi.person_id) AS total_person_cnt,
        COUNT(DISTINCT CASE WHEN n.gender = 'M' THEN pi.person_id END) AS male_person_cnt,
        COUNT(DISTINCT CASE WHEN n.gender = 'F' THEN pi.person_id END) AS female_person_cnt
    FROM person_info pi
    JOIN name n
        ON pi.person_id = n.id
    GROUP BY pi.info_type_id
)
SELECT
    it.info AS info_type,
    COALESCE(mi.movie_cnt, 0) AS movie_count,
    COALESCE(mi.avg_note_len, 0) AS avg_movie_note_length,
    COALESCE(pi.total_person_cnt, 0) AS person_count,
    COALESCE(pi.male_person_cnt, 0) AS male_person_count,
    COALESCE(pi.female_person_cnt, 0) AS female_person_count
FROM info_type it
LEFT JOIN movie_info_agg mi
    ON it.id = mi.info_type_id
LEFT JOIN person_info_agg pi
    ON it.id = pi.info_type_id
ORDER BY movie_count DESC, person_count DESC
LIMIT 10

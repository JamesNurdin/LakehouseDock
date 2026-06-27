WITH movie_agg AS (
    SELECT
        it.id AS info_type_id,
        it.info AS info_type,
        COUNT(DISTINCT mi.movie_id) AS movie_count,
        AVG(length(mi.info)) AS avg_movie_info_len
    FROM movie_info mi
    JOIN info_type it ON mi.info_type_id = it.id
    GROUP BY it.id, it.info
),
person_agg AS (
    SELECT
        it.id AS info_type_id,
        it.info AS info_type,
        COUNT(DISTINCT pi.person_id) AS person_count,
        COUNT(DISTINCT pi.person_id) FILTER (WHERE n.gender = 'M') AS male_person_count,
        COUNT(DISTINCT pi.person_id) FILTER (WHERE n.gender = 'F') AS female_person_count,
        AVG(length(pi.info)) AS avg_person_info_len
    FROM person_info pi
    JOIN info_type it ON pi.info_type_id = it.id
    JOIN name n ON pi.person_id = n.id
    GROUP BY it.id, it.info
)
SELECT
    COALESCE(ma.info_type, pa.info_type) AS info_type,
    COALESCE(ma.movie_count, 0) AS movie_count,
    COALESCE(pa.person_count, 0) AS person_count,
    COALESCE(pa.male_person_count, 0) AS male_persons,
    COALESCE(pa.female_person_count, 0) AS female_persons,
    COALESCE(ma.avg_movie_info_len, 0) AS avg_movie_info_len,
    COALESCE(pa.avg_person_info_len, 0) AS avg_person_info_len
FROM movie_agg ma
FULL OUTER JOIN person_agg pa
    ON ma.info_type_id = pa.info_type_id
ORDER BY movie_count DESC, person_count DESC

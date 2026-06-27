WITH person_counts AS (
    SELECT pi.info_type_id,
           COUNT(DISTINCT pi.person_id) AS person_count
    FROM person_info pi
    GROUP BY pi.info_type_id
),
movie_counts AS (
    SELECT mi.info_type_id,
           COUNT(DISTINCT mi.movie_id) AS movie_count
    FROM movie_info_idx mi
    GROUP BY mi.info_type_id
)
SELECT
    it.info AS info_type,
    COALESCE(pc.person_count, 0) AS person_count,
    COALESCE(mc.movie_count, 0) AS movie_count
FROM info_type it
LEFT JOIN person_counts pc ON pc.info_type_id = it.id
LEFT JOIN movie_counts mc ON mc.info_type_id = it.id
ORDER BY person_count DESC, movie_count DESC
LIMIT 20

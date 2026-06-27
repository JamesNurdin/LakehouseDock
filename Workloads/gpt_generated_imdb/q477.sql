WITH movie_counts AS (
    SELECT it.id AS info_type_id,
           COUNT(mi.id) AS movie_info_cnt,
           COUNT(DISTINCT mi.movie_id) AS distinct_movie_cnt,
           AVG(mi.note) AS avg_movie_note
    FROM movie_info_idx mi
    JOIN info_type it
      ON mi.info_type_id = it.id
    GROUP BY it.id
),
person_counts AS (
    SELECT it.id AS info_type_id,
           COUNT(pi.id) AS person_info_cnt,
           COUNT(DISTINCT pi.person_id) AS distinct_person_cnt
    FROM person_info pi
    JOIN info_type it
      ON pi.info_type_id = it.id
    GROUP BY it.id
)
SELECT it.info AS info_type,
       mc.movie_info_cnt,
       mc.distinct_movie_cnt,
       mc.avg_movie_note,
       pc.person_info_cnt,
       pc.distinct_person_cnt,
       CASE
           WHEN pc.distinct_person_cnt = 0 THEN NULL
           ELSE mc.distinct_movie_cnt * 1.0 / pc.distinct_person_cnt
       END AS movie_to_person_ratio
FROM info_type it
LEFT JOIN movie_counts mc
  ON it.id = mc.info_type_id
LEFT JOIN person_counts pc
  ON it.id = pc.info_type_id
ORDER BY mc.distinct_movie_cnt DESC NULLS LAST
LIMIT 20

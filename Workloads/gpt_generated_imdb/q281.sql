WITH movie_stats AS (
    SELECT it.info AS info_type,
           COUNT(*) AS movie_info_cnt,
           AVG(mii.note) AS avg_movie_note
    FROM movie_info_idx mii
    JOIN info_type it
      ON mii.info_type_id = it.id
    GROUP BY it.info
),
person_stats AS (
    SELECT it.info AS info_type,
           n.gender,
           COUNT(*) AS person_info_cnt,
           COUNT(DISTINCT pi.person_id) AS distinct_person_cnt
    FROM person_info pi
    JOIN info_type it
      ON pi.info_type_id = it.id
    JOIN name n
      ON pi.person_id = n.id
    GROUP BY it.info, n.gender
),
person_stats_ranked AS (
    SELECT ps.info_type,
           ps.gender,
           ps.person_info_cnt,
           ps.distinct_person_cnt,
           ROW_NUMBER() OVER (PARTITION BY ps.info_type ORDER BY ps.person_info_cnt DESC) AS gender_rank
    FROM person_stats ps
)
SELECT ms.info_type,
       ms.movie_info_cnt,
       ms.avg_movie_note,
       psr.gender,
       psr.person_info_cnt,
       psr.distinct_person_cnt,
       psr.gender_rank
FROM movie_stats ms
LEFT JOIN person_stats_ranked psr
  ON ms.info_type = psr.info_type
ORDER BY ms.movie_info_cnt DESC, psr.gender_rank
LIMIT 50

WITH movie_stats AS (
   SELECT i.id AS info_type_id,
          i.info AS info_type,
          AVG(m.note) AS avg_movie_note,
          COUNT(DISTINCT m.movie_id) AS movie_count
   FROM movie_info_idx m
   JOIN info_type i ON i.id = m.info_type_id
   WHERE m.note IS NOT NULL
   GROUP BY i.id, i.info
),
person_stats AS (
   SELECT i.id AS info_type_id,
          i.info AS info_type,
          COUNT(DISTINCT p.person_id) AS person_count
   FROM person_info p
   JOIN info_type i ON i.id = p.info_type_id
   GROUP BY i.id, i.info
)
SELECT ms.info_type,
       ms.avg_movie_note,
       ms.movie_count,
       ps.person_count
FROM movie_stats ms
LEFT JOIN person_stats ps ON ps.info_type_id = ms.info_type_id
ORDER BY ms.avg_movie_note DESC
LIMIT 20

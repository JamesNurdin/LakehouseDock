WITH movie_info AS (
  SELECT
    mi.id AS mi_id,
    mi.movie_id,
    mi.info_type_id,
    mi.info AS info_value,
    mi.note,
    t.title,
    t.production_year,
    it.info AS info_type_name
  FROM movie_info_idx mi
  JOIN title t ON mi.movie_id = t.id
  JOIN info_type it ON mi.info_type_id = it.id
  WHERE t.production_year IS NOT NULL
)
SELECT
  info_type_name,
  COUNT(DISTINCT movie_id) AS movie_count,
  AVG(note) AS avg_note,
  MIN(production_year) AS earliest_year,
  MAX(production_year) AS latest_year
FROM movie_info
GROUP BY info_type_name
ORDER BY avg_note DESC
LIMIT 10

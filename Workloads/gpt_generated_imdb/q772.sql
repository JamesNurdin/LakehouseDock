WITH keyword_year_stats AS (
  SELECT
    t.production_year,
    k.keyword,
    COUNT(DISTINCT t.id) AS movie_count,
    AVG(mi_idx.note) AS avg_note,
    COUNT(DISTINCT mi.id) AS info_entry_count
  FROM title t
  JOIN movie_keyword mk ON mk.movie_id = t.id
  JOIN keyword k ON k.id = mk.keyword_id
  LEFT JOIN movie_info_idx mi_idx ON mi_idx.movie_id = t.id AND mi_idx.info_type_id = 1
  LEFT JOIN movie_info mi ON mi.movie_id = t.id
  WHERE t.production_year IS NOT NULL
    AND t.production_year >= 2000
  GROUP BY t.production_year, k.keyword
)
SELECT
  production_year,
  keyword,
  movie_count,
  avg_note,
  info_entry_count
FROM (
  SELECT
    production_year,
    keyword,
    movie_count,
    avg_note,
    info_entry_count,
    ROW_NUMBER() OVER (PARTITION BY production_year ORDER BY movie_count DESC) AS rn
  FROM keyword_year_stats
) ranked_keywords
WHERE rn <= 5
ORDER BY production_year, movie_count DESC

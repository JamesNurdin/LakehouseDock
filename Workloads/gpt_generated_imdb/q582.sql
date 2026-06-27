WITH movie_cast_counts AS (
  SELECT
    t.id AS movie_id,
    t.production_year,
    kt.kind AS kind,
    COUNT(DISTINCT ci.person_id) AS cast_count,
    COUNT(DISTINCT CASE WHEN n.gender = 'M' THEN n.id END) AS male_cast_count,
    COUNT(DISTINCT CASE WHEN n.gender = 'F' THEN n.id END) AS female_cast_count
  FROM title t
  JOIN kind_type kt ON kt.id = t.kind_id
  JOIN cast_info ci ON ci.movie_id = t.id
  JOIN name n ON n.id = ci.person_id
  WHERE t.production_year BETWEEN 2000 AND 2020
  GROUP BY t.id, t.production_year, kt.kind
)
SELECT
  production_year,
  kind,
  COUNT(*) AS total_titles,
  SUM(cast_count) AS total_cast,
  AVG(cast_count) AS avg_cast_per_title,
  SUM(male_cast_count) AS total_male_cast,
  SUM(female_cast_count) AS total_female_cast,
  ROUND(100.0 * SUM(male_cast_count) / NULLIF(SUM(male_cast_count) + SUM(female_cast_count), 0), 2) AS pct_male_cast,
  ROUND(100.0 * SUM(female_cast_count) / NULLIF(SUM(male_cast_count) + SUM(female_cast_count), 0), 2) AS pct_female_cast
FROM movie_cast_counts
GROUP BY production_year, kind
ORDER BY production_year, kind

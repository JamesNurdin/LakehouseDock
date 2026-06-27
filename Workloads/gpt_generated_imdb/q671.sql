WITH info_counts AS (
  SELECT
    it.id AS info_type_id,
    it.info AS info_type,
    count(DISTINCT t.id) AS movie_count,
    count(*) AS record_count,
    avg(t.production_year) AS avg_production_year,
    min(t.production_year) AS min_production_year,
    max(t.production_year) AS max_production_year
  FROM movie_info mi
  JOIN title t ON mi.movie_id = t.id
  JOIN info_type it ON mi.info_type_id = it.id
  WHERE t.kind_id = 1
  GROUP BY it.id, it.info
),
info_top_counts AS (
  SELECT
    it.id AS info_type_id,
    mi.info AS info_value,
    count(*) AS value_count
  FROM movie_info mi
  JOIN title t ON mi.movie_id = t.id
  JOIN info_type it ON mi.info_type_id = it.id
  WHERE t.kind_id = 1
  GROUP BY it.id, mi.info
),
info_top_values AS (
  SELECT
    info_type_id,
    info_value,
    value_count,
    row_number() OVER (PARTITION BY info_type_id ORDER BY value_count DESC) AS rn
  FROM info_top_counts
)
SELECT
  ic.info_type,
  ic.movie_count,
  ic.record_count,
  ic.avg_production_year,
  ic.min_production_year,
  ic.max_production_year,
  itv.info_value AS top_info_value,
  itv.value_count AS top_value_count
FROM info_counts ic
LEFT JOIN info_top_values itv
  ON ic.info_type_id = itv.info_type_id
  AND itv.rn = 1
ORDER BY ic.movie_count DESC
LIMIT 20

SELECT
    kt.kind,
    COUNT(t.id) AS title_count,
    COUNT(DISTINCT t.imdb_id) AS distinct_imdb_ids,
    (COUNT(DISTINCT t.imdb_id) * 100.0) / COUNT(t.id) AS distinct_imdb_percent,
    AVG(t.production_year) AS avg_production_year,
    approx_percentile(t.production_year, 0.5) AS median_production_year,
    MIN(t.production_year) AS min_production_year,
    MAX(t.production_year) AS max_production_year
FROM title t
JOIN kind_type kt ON t.kind_id = kt.id
WHERE t.production_year BETWEEN 2000 AND 2020
GROUP BY kt.kind
HAVING COUNT(t.id) > 100
ORDER BY title_count DESC

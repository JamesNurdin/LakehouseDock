SELECT
    kt.kind,
    floor(t.production_year / 10) * 10 AS decade,
    COUNT(t.id) AS title_count,
    AVG(t.production_year) AS avg_production_year
FROM title t
JOIN kind_type kt ON t.kind_id = kt.id
WHERE t.production_year IS NOT NULL
GROUP BY kt.kind, floor(t.production_year / 10) * 10
ORDER BY title_count DESC
LIMIT 20

SELECT
    t.title,
    t.production_year,
    COUNT(DISTINCT ci.person_id) AS cast_count,
    COUNT(DISTINCT mi_idx.info_type_id) AS info_type_count
FROM title t
LEFT JOIN cast_info ci
    ON ci.movie_id = t.id
LEFT JOIN movie_info_idx mi_idx
    ON mi_idx.movie_id = t.id
WHERE t.kind_id = 1
  AND t.production_year >= 2000
GROUP BY t.title, t.production_year
ORDER BY cast_count DESC
LIMIT 20

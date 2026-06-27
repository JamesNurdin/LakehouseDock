SELECT
    t.title,
    t.production_year,
    kt.kind,
    COUNT(DISTINCT ci.person_id) AS cast_cnt,
    COUNT(DISTINCT mk.keyword_id) AS kw_cnt
FROM title t
JOIN kind_type kt ON t.kind_id = kt.id
LEFT JOIN cast_info ci ON ci.movie_id = t.id
LEFT JOIN movie_keyword mk ON mk.movie_id = t.id
WHERE t.production_year IS NOT NULL
GROUP BY t.id, t.title, t.production_year, kt.kind
ORDER BY cast_cnt DESC, kw_cnt DESC
LIMIT 10

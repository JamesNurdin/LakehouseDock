SELECT
    k.keyword,
    kt.kind,
    COUNT(DISTINCT t.id) AS movie_count,
    AVG(t.production_year) AS avg_production_year,
    AVG(mi.note) AS avg_rating
FROM
    title t
JOIN kind_type kt
    ON t.kind_id = kt.id
JOIN movie_keyword mk
    ON mk.movie_id = t.id
JOIN keyword k
    ON mk.keyword_id = k.id
LEFT JOIN movie_info_idx mi
    ON mi.movie_id = t.id
    AND mi.info_type_id = 101
WHERE
    t.production_year BETWEEN 2000 AND 2020
GROUP BY
    k.keyword,
    kt.kind
ORDER BY
    movie_count DESC
LIMIT 20

WITH cast_counts AS (
    SELECT
        ci.movie_id,
        COUNT(DISTINCT ci.person_id) AS cast_count
    FROM cast_info ci
    GROUP BY ci.movie_id
)
SELECT
    kt.kind AS genre,
    k.keyword,
    COUNT(DISTINCT t.id) AS movie_count,
    AVG(cc.cast_count) AS avg_cast_per_movie
FROM title t
JOIN kind_type kt ON t.kind_id = kt.id
JOIN movie_keyword mk ON mk.movie_id = t.id
JOIN keyword k ON mk.keyword_id = k.id
JOIN cast_counts cc ON cc.movie_id = t.id
WHERE t.production_year BETWEEN 2000 AND 2020
GROUP BY kt.kind, k.keyword
ORDER BY movie_count DESC
LIMIT 20

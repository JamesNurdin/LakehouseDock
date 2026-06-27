-- Count movies after year 2000 per kind and company type, and average distinct cast per movie
WITH movie_cast_counts AS (
    SELECT
        ci.movie_id,
        COUNT(DISTINCT ci.person_id) AS cast_count
    FROM cast_info ci
    GROUP BY ci.movie_id
)
SELECT
    kt.kind,
    mc.company_type_id,
    COUNT(DISTINCT t.id) AS num_movies,
    AVG(mcc.cast_count) AS avg_cast_per_movie
FROM movie_companies mc
JOIN title t
    ON mc.movie_id = t.id
JOIN kind_type kt
    ON t.kind_id = kt.id
LEFT JOIN movie_cast_counts mcc
    ON t.id = mcc.movie_id
WHERE t.production_year >= 2000
GROUP BY kt.kind, mc.company_type_id
ORDER BY kt.kind, mc.company_type_id

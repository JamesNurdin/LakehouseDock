WITH cast_counts AS (
    SELECT
        movie_id,
        COUNT(DISTINCT person_id) AS cast_count
    FROM cast_info
    GROUP BY movie_id
),
company_counts AS (
    SELECT
        movie_id,
        COUNT(DISTINCT company_id) AS company_count
    FROM movie_companies
    GROUP BY movie_id
),
runtime_info AS (
    SELECT
        mi.movie_id,
        CAST(mi.info AS double) AS runtime_minutes
    FROM movie_info_idx mi
    JOIN info_type it ON mi.info_type_id = it.id
    WHERE it.info = 'runtime'
)
SELECT
    kt.kind AS title_kind,
    COUNT(t.id) AS movie_count,
    AVG(r.runtime_minutes) AS avg_runtime_minutes,
    AVG(c.cast_count) AS avg_cast_per_movie,
    AVG(co.company_count) AS avg_companies_per_movie
FROM title t
JOIN kind_type kt ON t.kind_id = kt.id
LEFT JOIN cast_counts c ON t.id = c.movie_id
LEFT JOIN company_counts co ON t.id = co.movie_id
LEFT JOIN runtime_info r ON t.id = r.movie_id
GROUP BY kt.kind
ORDER BY movie_count DESC

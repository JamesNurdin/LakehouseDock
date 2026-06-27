WITH movie_stats AS (
    SELECT
        t.id AS movie_id,
        t.title,
        t.production_year,
        kt.kind,
        COUNT(DISTINCT ci.person_id) AS cast_count,
        COUNT(DISTINCT mc.company_id) AS company_count,
        AVG(CAST(mi.info AS double)) AS avg_rating
    FROM title t
    LEFT JOIN kind_type kt
        ON t.kind_id = kt.id
    LEFT JOIN cast_info ci
        ON ci.movie_id = t.id
    LEFT JOIN movie_companies mc
        ON mc.movie_id = t.id
    LEFT JOIN movie_info mi
        ON mi.movie_id = t.id
        AND mi.info_type_id = 3   -- assumed rating type
    GROUP BY
        t.id,
        t.title,
        t.production_year,
        kt.kind
)
SELECT
    production_year,
    kind,
    COUNT(*) AS num_movies,
    AVG(cast_count) AS avg_cast_per_movie,
    AVG(company_count) AS avg_company_per_movie,
    AVG(avg_rating) AS avg_rating
FROM movie_stats
WHERE production_year IS NOT NULL
GROUP BY
    production_year,
    kind
ORDER BY
    production_year DESC,
    kind

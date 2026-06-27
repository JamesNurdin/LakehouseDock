WITH prod_company_stats AS (
    SELECT
        cn.id AS company_id,
        cn.name AS company_name,
        COUNT(DISTINCT t.id) AS movie_count,
        COUNT(DISTINCT ci.person_id) AS distinct_cast_count
    FROM movie_companies mc
    JOIN company_name cn ON mc.company_id = cn.id
    JOIN company_type ct ON mc.company_type_id = ct.id
    JOIN title t ON mc.movie_id = t.id
    JOIN kind_type kt ON t.kind_id = kt.id
    LEFT JOIN cast_info ci ON ci.movie_id = t.id
    WHERE ct.kind = 'production company'
      AND kt.kind = 'movie'
      AND t.production_year >= 2000
    GROUP BY cn.id, cn.name
)
SELECT
    company_id,
    company_name,
    movie_count,
    distinct_cast_count,
    CAST(distinct_cast_count AS double) / NULLIF(movie_count, 0) AS avg_cast_per_movie
FROM prod_company_stats
ORDER BY movie_count DESC
LIMIT 10

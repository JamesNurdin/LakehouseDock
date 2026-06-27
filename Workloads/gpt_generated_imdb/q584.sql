WITH movie_cast AS (
    SELECT
        ci.movie_id,
        COUNT(DISTINCT ci.person_id) AS cast_size
    FROM cast_info ci
    JOIN title t ON ci.movie_id = t.id
    WHERE t.production_year >= 2000
    GROUP BY ci.movie_id
),
company_stats AS (
    SELECT
        cn.name AS company_name,
        COUNT(DISTINCT mc.movie_id) AS num_movies,
        AVG(mc_cast.cast_size) AS avg_cast_size,
        AVG(t.production_year) AS avg_production_year
    FROM movie_companies mc
    JOIN title t ON mc.movie_id = t.id
    JOIN kind_type kt ON t.kind_id = kt.id
    JOIN company_type ct ON mc.company_type_id = ct.id
    JOIN company_name cn ON mc.company_id = cn.id
    JOIN movie_cast mc_cast ON mc_cast.movie_id = t.id
    WHERE t.production_year >= 2000
      AND kt.kind = 'movie'
      AND ct.kind = 'production company'
    GROUP BY cn.name
)
SELECT
    company_name,
    num_movies,
    avg_cast_size,
    avg_production_year
FROM company_stats
ORDER BY avg_cast_size DESC
LIMIT 5

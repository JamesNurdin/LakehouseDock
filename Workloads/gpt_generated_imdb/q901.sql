WITH company_movie_stats AS (
    SELECT
        cn.id AS company_id,
        cn.name,
        cn.country_code,
        COUNT(DISTINCT mc.movie_id) AS movie_count,
        COUNT(DISTINCT ct.kind) AS distinct_type_count
    FROM movie_companies mc
    JOIN company_name cn ON mc.company_id = cn.id
    JOIN company_type ct ON mc.company_type_id = ct.id
    GROUP BY cn.id, cn.name, cn.country_code
),
ranked_companies AS (
    SELECT
        company_id,
        name,
        country_code,
        movie_count,
        distinct_type_count,
        ROW_NUMBER() OVER (PARTITION BY country_code ORDER BY movie_count DESC) AS rank_in_country
    FROM company_movie_stats
)
SELECT
    company_id,
    name,
    country_code,
    movie_count,
    distinct_type_count,
    rank_in_country
FROM ranked_companies
WHERE rank_in_country <= 5
ORDER BY country_code, rank_in_country

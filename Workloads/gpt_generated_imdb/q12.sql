WITH company_movie_stats AS (
    SELECT
        cn.id AS company_id,
        cn.name AS company_name,
        cn.country_code,
        ct.kind AS company_type,
        kt.kind AS title_kind,
        t.production_year,
        COUNT(DISTINCT t.id) AS movie_count
    FROM movie_companies mc
    JOIN title t               ON mc.movie_id = t.id
    JOIN company_name cn       ON mc.company_id = cn.id
    JOIN company_type ct       ON mc.company_type_id = ct.id
    JOIN kind_type kt          ON t.kind_id = kt.id
    WHERE t.production_year BETWEEN 2000 AND 2020
    GROUP BY cn.id, cn.name, cn.country_code, ct.kind, kt.kind, t.production_year
),
ranked_stats AS (
    SELECT
        company_name,
        country_code,
        company_type,
        title_kind,
        production_year,
        movie_count,
        RANK() OVER (PARTITION BY company_type ORDER BY movie_count DESC) AS rank_within_type
    FROM company_movie_stats
)
SELECT
    company_name,
    country_code,
    company_type,
    title_kind,
    production_year,
    movie_count,
    rank_within_type
FROM ranked_stats
WHERE rank_within_type <= 5
ORDER BY company_type, rank_within_type

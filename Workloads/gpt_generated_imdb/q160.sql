WITH company_movie_stats AS (
    SELECT
        cn.id AS company_id,
        cn.name AS company_name,
        cn.country_code,
        ct.kind AS company_type,
        kt.kind AS title_kind,
        COUNT(DISTINCT t.id) AS movie_count,
        MIN(t.production_year) AS earliest_year,
        MAX(t.production_year) AS latest_year,
        AVG(t.production_year) AS avg_year
    FROM movie_companies mc
    JOIN title t ON mc.movie_id = t.id
    JOIN company_name cn ON mc.company_id = cn.id
    JOIN company_type ct ON mc.company_type_id = ct.id
    JOIN kind_type kt ON t.kind_id = kt.id
    WHERE t.production_year >= 2000 AND t.production_year <= 2020
    GROUP BY cn.id, cn.name, cn.country_code, ct.kind, kt.kind
),
ranked_companies AS (
    SELECT
        company_id,
        company_name,
        country_code,
        company_type,
        title_kind,
        movie_count,
        earliest_year,
        latest_year,
        avg_year,
        ROW_NUMBER() OVER (PARTITION BY company_type ORDER BY movie_count DESC) AS rn
    FROM company_movie_stats
)
SELECT
    company_name,
    country_code,
    company_type,
    title_kind,
    movie_count,
    earliest_year,
    latest_year,
    avg_year
FROM ranked_companies
WHERE rn <= 5
ORDER BY company_type, rn

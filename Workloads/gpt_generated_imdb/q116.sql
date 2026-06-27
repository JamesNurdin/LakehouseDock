WITH company_year_kind_counts AS (
    SELECT
        cn.name AS company_name,
        cn.country_code,
        ct.kind AS company_type,
        k.kind AS movie_kind,
        t.production_year AS production_year,
        COUNT(DISTINCT t.id) AS movie_count
    FROM movie_companies mc
    JOIN title t ON mc.movie_id = t.id
    JOIN company_name cn ON mc.company_id = cn.id
    JOIN company_type ct ON mc.company_type_id = ct.id
    JOIN kind_type k ON t.kind_id = k.id
    WHERE ct.kind = 'production'
      AND t.production_year IS NOT NULL
    GROUP BY cn.name, cn.country_code, ct.kind, k.kind, t.production_year
),
ranked_company_counts AS (
    SELECT
        company_name,
        country_code,
        company_type,
        movie_kind,
        production_year,
        movie_count,
        RANK() OVER (PARTITION BY production_year, movie_kind ORDER BY movie_count DESC) AS rank_in_year_kind
    FROM company_year_kind_counts
)
SELECT
    company_name,
    country_code,
    company_type,
    movie_kind,
    production_year,
    movie_count,
    rank_in_year_kind
FROM ranked_company_counts
WHERE rank_in_year_kind <= 3
ORDER BY production_year DESC, movie_kind, rank_in_year_kind

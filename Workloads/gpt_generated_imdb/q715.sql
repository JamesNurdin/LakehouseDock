WITH movie_company_counts AS (
    SELECT
        t.production_year,
        kt.kind AS title_kind,
        cn.name AS company_name,
        ct.kind AS company_type,
        COUNT(DISTINCT t.id) AS movie_count
    FROM title t
    JOIN kind_type kt
        ON t.kind_id = kt.id
    JOIN movie_companies mc
        ON mc.movie_id = t.id
    JOIN company_name cn
        ON mc.company_id = cn.id
    JOIN company_type ct
        ON mc.company_type_id = ct.id
    WHERE t.production_year IS NOT NULL
    GROUP BY t.production_year, kt.kind, cn.name, ct.kind
),
ranked_companies AS (
    SELECT
        production_year,
        title_kind,
        company_name,
        company_type,
        movie_count,
        ROW_NUMBER() OVER (PARTITION BY production_year, title_kind ORDER BY movie_count DESC) AS rank
    FROM movie_company_counts
)
SELECT
    production_year,
    title_kind,
    company_name,
    company_type,
    movie_count
FROM ranked_companies
WHERE rank <= 3
ORDER BY production_year DESC, title_kind, rank

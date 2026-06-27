WITH company_year_counts AS (
    SELECT
        cn.name AS company_name,
        ct.kind AS company_type,
        CAST(t.production_year AS integer) AS production_year,
        COUNT(DISTINCT t.id) AS movie_count
    FROM movie_companies mc
    JOIN company_name cn ON mc.company_id = cn.id
    JOIN company_type ct ON mc.company_type_id = ct.id
    JOIN title t ON mc.movie_id = t.id
    JOIN kind_type kt ON t.kind_id = kt.id
    WHERE CAST(t.production_year AS integer) BETWEEN 2000 AND 2020
      AND kt.kind = 'movie'
    GROUP BY cn.name, ct.kind, CAST(t.production_year AS integer)
),
ranked_counts AS (
    SELECT
        company_name,
        company_type,
        production_year,
        movie_count,
        RANK() OVER (PARTITION BY production_year ORDER BY movie_count DESC) AS rank_in_year
    FROM company_year_counts
)
SELECT
    company_name,
    company_type,
    production_year,
    movie_count,
    rank_in_year
FROM ranked_counts
WHERE rank_in_year <= 5
ORDER BY production_year, rank_in_year

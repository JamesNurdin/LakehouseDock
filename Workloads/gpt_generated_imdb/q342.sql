WITH actor_year_stats AS (
    SELECT
        t.production_year,
        n.id AS person_id,
        n.name,
        COUNT(DISTINCT t.id) AS movie_count,
        COUNT(DISTINCT CASE WHEN ct.kind = 'production company' THEN cn.id END) AS distinct_production_companies
    FROM title t
    JOIN kind_type kt ON t.kind_id = kt.id
    JOIN cast_info ci ON ci.movie_id = t.id
    JOIN name n ON ci.person_id = n.id
    LEFT JOIN movie_companies mc ON mc.movie_id = t.id
    LEFT JOIN company_type ct ON mc.company_type_id = ct.id
    LEFT JOIN company_name cn ON mc.company_id = cn.id
    WHERE kt.kind = 'movie'
      AND t.production_year IS NOT NULL
    GROUP BY t.production_year, n.id, n.name
)
SELECT
    production_year,
    person_id,
    name,
    movie_count,
    distinct_production_companies,
    rank_in_year
FROM (
    SELECT
        production_year,
        person_id,
        name,
        movie_count,
        distinct_production_companies,
        ROW_NUMBER() OVER (
            PARTITION BY production_year
            ORDER BY movie_count DESC, distinct_production_companies DESC
        ) AS rank_in_year
    FROM actor_year_stats
) ranked
WHERE rank_in_year <= 5
ORDER BY production_year DESC, rank_in_year

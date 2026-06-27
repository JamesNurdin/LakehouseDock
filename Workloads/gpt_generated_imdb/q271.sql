WITH total_movies_per_company AS (
    SELECT
        mc.company_id,
        COUNT(DISTINCT t.id) AS total_movies
    FROM movie_companies mc
    JOIN title t
        ON mc.movie_id = t.id
    WHERE t.production_year IS NOT NULL
      AND t.production_year BETWEEN 2000 AND 2020
    GROUP BY mc.company_id
),
top_companies AS (
    SELECT company_id
    FROM total_movies_per_company
    ORDER BY total_movies DESC
    LIMIT 10
),
company_yearly AS (
    SELECT
        mc.company_id,
        CAST(t.production_year AS integer) AS prod_year,
        COUNT(DISTINCT t.id) AS movies_per_year
    FROM movie_companies mc
    JOIN title t
        ON mc.movie_id = t.id
    WHERE mc.company_id IN (SELECT company_id FROM top_companies)
      AND t.production_year IS NOT NULL
      AND t.production_year BETWEEN 2000 AND 2020
    GROUP BY mc.company_id, CAST(t.production_year AS integer)
)
SELECT
    cy.company_id,
    cy.prod_year,
    cy.movies_per_year,
    SUM(cy.movies_per_year) OVER (PARTITION BY cy.company_id ORDER BY cy.prod_year) AS cumulative_movies
FROM company_yearly cy
ORDER BY cy.company_id, cy.prod_year

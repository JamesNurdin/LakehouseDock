WITH movie_company_keyword AS (
    SELECT
        mc.company_type_id,
        mk.keyword_id,
        t.id AS movie_id,
        t.production_year
    FROM movie_companies mc
    JOIN title t ON mc.movie_id = t.id
    JOIN movie_keyword mk ON mk.movie_id = t.id
),
agg AS (
    SELECT
        company_type_id,
        keyword_id,
        COUNT(DISTINCT movie_id) AS movie_cnt,
        AVG(production_year) AS avg_prod_year
    FROM movie_company_keyword
    GROUP BY company_type_id, keyword_id
)
SELECT
    company_type_id,
    keyword_id,
    movie_cnt,
    avg_prod_year
FROM (
    SELECT
        company_type_id,
        keyword_id,
        movie_cnt,
        avg_prod_year,
        ROW_NUMBER() OVER (PARTITION BY company_type_id ORDER BY movie_cnt DESC) AS rn
    FROM agg
) ranked
WHERE rn <= 5
ORDER BY company_type_id, movie_cnt DESC

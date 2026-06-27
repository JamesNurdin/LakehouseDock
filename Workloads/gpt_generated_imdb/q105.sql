WITH keyword_counts AS (
    SELECT
        CAST(t.production_year AS integer) AS prod_year,
        k.keyword,
        COUNT(DISTINCT mk.movie_id) AS movie_count,
        COUNT(DISTINCT mc.company_id) AS company_count
    FROM title t
    JOIN movie_keyword mk ON mk.movie_id = t.id
    JOIN keyword k ON k.id = mk.keyword_id
    LEFT JOIN movie_companies mc ON mc.movie_id = t.id
    WHERE CAST(t.production_year AS integer) >= 2000
    GROUP BY
        CAST(t.production_year AS integer),
        k.keyword
)
SELECT
    prod_year,
    keyword,
    movie_count,
    company_count
FROM (
    SELECT
        prod_year,
        keyword,
        movie_count,
        company_count,
        ROW_NUMBER() OVER (PARTITION BY prod_year ORDER BY movie_count DESC) AS rn
    FROM keyword_counts
) sub
WHERE rn <= 5
ORDER BY prod_year, movie_count DESC

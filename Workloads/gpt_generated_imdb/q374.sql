/*
  Top 5 keywords per production year for titles that are movies (kind_id = 1)
  and are associated with production companies (company_type_id = 1).
  The query counts distinct movies for each keyword per year, ranks the keywords
  per year by that count, and returns the five most frequent keywords for each year.
*/
WITH keyword_counts AS (
    SELECT
        CAST(t.production_year AS integer) AS prod_year,
        k.keyword,
        COUNT(DISTINCT t.id) AS movie_cnt
    FROM title t
    JOIN movie_keyword mk ON mk.movie_id = t.id
    JOIN keyword k ON k.id = mk.keyword_id
    JOIN movie_companies mc ON mc.movie_id = t.id
    WHERE t.kind_id = 1
      AND mc.company_type_id = 1
      AND t.production_year BETWEEN 2000 AND 2020
    GROUP BY CAST(t.production_year AS integer), k.keyword
),
ranked_keywords AS (
    SELECT
        prod_year,
        keyword,
        movie_cnt,
        ROW_NUMBER() OVER (PARTITION BY prod_year ORDER BY movie_cnt DESC) AS rn
    FROM keyword_counts
)
SELECT
    prod_year,
    keyword,
    movie_cnt
FROM ranked_keywords
WHERE rn <= 5
ORDER BY prod_year DESC, movie_cnt DESC

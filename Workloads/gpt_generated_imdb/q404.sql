/* Top 5 keywords by number of movies for each production year between 2000 and 2020 */
WITH kw_year_counts AS (
    SELECT
        CAST(t.production_year AS integer) AS prod_year,
        k.id AS keyword_id,
        k.keyword,
        COUNT(DISTINCT mk.movie_id) AS movie_cnt
    FROM title t
    JOIN movie_keyword mk ON mk.movie_id = t.id
    JOIN keyword k ON mk.keyword_id = k.id
    WHERE t.production_year IS NOT NULL
    GROUP BY
        CAST(t.production_year AS integer),
        k.id,
        k.keyword
),
kw_year_rank AS (
    SELECT
        prod_year,
        keyword,
        movie_cnt,
        ROW_NUMBER() OVER (PARTITION BY prod_year ORDER BY movie_cnt DESC) AS rn
    FROM kw_year_counts
)
SELECT
    prod_year,
    keyword,
    movie_cnt AS movie_count
FROM kw_year_rank
WHERE rn <= 5
  AND prod_year BETWEEN 2000 AND 2020
ORDER BY prod_year DESC, rn

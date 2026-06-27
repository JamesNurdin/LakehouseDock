WITH keyword_counts AS (
    SELECT
        CAST(t.production_year AS integer) AS prod_year,
        k.keyword,
        COUNT(DISTINCT t.id) AS movie_cnt
    FROM title t
    JOIN movie_keyword mk
        ON mk.movie_id = t.id
    JOIN keyword k
        ON mk.keyword_id = k.id
    JOIN movie_info mi
        ON mi.movie_id = t.id
    WHERE t.production_year >= 2000
      AND mi.info_type_id IS NOT NULL
    GROUP BY
        CAST(t.production_year AS integer),
        k.keyword
)
SELECT
    prod_year,
    keyword,
    movie_cnt
FROM (
    SELECT
        prod_year,
        keyword,
        movie_cnt,
        ROW_NUMBER() OVER (PARTITION BY prod_year ORDER BY movie_cnt DESC) AS rk
    FROM keyword_counts
) ranked
WHERE rk <= 5
ORDER BY prod_year, rk

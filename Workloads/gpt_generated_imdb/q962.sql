-- Top keywords for movies released from 2000 onward, with movie counts, total and average company involvement, ranked per year
WITH movie_company_counts AS (
    SELECT mc.movie_id,
           COUNT(DISTINCT mc.company_id) AS company_cnt
    FROM movie_companies mc
    GROUP BY mc.movie_id
)
SELECT
    keyword,
    prod_year,
    movie_count,
    total_company_count,
    avg_companies_per_movie,
    RANK() OVER (PARTITION BY prod_year ORDER BY movie_count DESC) AS rank_in_year
FROM (
    SELECT
        kw.keyword AS keyword,
        CAST(t.production_year AS integer) AS prod_year,
        COUNT(DISTINCT t.id) AS movie_count,
        SUM(mcc.company_cnt) AS total_company_count,
        AVG(mcc.company_cnt) AS avg_companies_per_movie
    FROM title t
    JOIN kind_type kt ON t.kind_id = kt.id
    JOIN movie_keyword mk ON mk.movie_id = t.id
    JOIN keyword kw ON kw.id = mk.keyword_id
    JOIN movie_company_counts mcc ON mcc.movie_id = t.id
    WHERE kt.kind = 'movie'
      AND t.production_year >= 2000
    GROUP BY kw.keyword, CAST(t.production_year AS integer)
) q
ORDER BY prod_year DESC, movie_count DESC
LIMIT 20

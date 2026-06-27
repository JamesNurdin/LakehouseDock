WITH movie_data AS (
    SELECT
        mc.company_id,
        mk.keyword,
        t.id AS movie_id,
        t.production_year,
        kt.kind
    FROM movie_companies mc
    JOIN title t
        ON mc.movie_id = t.id
    JOIN kind_type kt
        ON t.kind_id = kt.id
    JOIN movie_keyword mkj
        ON mkj.movie_id = t.id
    JOIN keyword mk
        ON mk.id = mkj.keyword_id
    WHERE t.production_year BETWEEN 1990 AND 1999
      AND kt.kind = 'movie'
)
SELECT
    company_id,
    keyword,
    movie_count
FROM (
    SELECT
        company_id,
        keyword,
        COUNT(DISTINCT movie_id) AS movie_count,
        ROW_NUMBER() OVER (PARTITION BY company_id ORDER BY COUNT(DISTINCT movie_id) DESC) AS rn
    FROM movie_data
    GROUP BY company_id, keyword
) t
WHERE rn <= 3
ORDER BY company_id, movie_count DESC

WITH movies_per_keyword AS (
    SELECT
        k.id AS keyword_id,
        k.keyword,
        t.id AS movie_id
    FROM title t
    JOIN movie_keyword mk ON t.id = mk.movie_id
    JOIN keyword k ON mk.keyword_id = k.id
    WHERE t.production_year = 2020
),
companies_per_movie AS (
    SELECT
        mc.movie_id,
        mc.company_id
    FROM movie_companies mc
),
keyword_aggregates AS (
    SELECT
        mkq.keyword_id,
        mkq.keyword,
        COUNT(DISTINCT mkq.movie_id) AS movie_count,
        COUNT(DISTINCT cpm.company_id) AS company_count
    FROM movies_per_keyword mkq
    LEFT JOIN companies_per_movie cpm
        ON mkq.movie_id = cpm.movie_id
    GROUP BY mkq.keyword_id, mkq.keyword
)
SELECT
    keyword_id,
    keyword,
    movie_count,
    company_count,
    ROW_NUMBER() OVER (ORDER BY movie_count DESC, company_count DESC) AS rank
FROM keyword_aggregates
WHERE movie_count > 0
ORDER BY rank
LIMIT 5

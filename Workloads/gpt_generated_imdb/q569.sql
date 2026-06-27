WITH keyword_by_year AS (
    SELECT
        t.production_year,
        mk.keyword_id,
        COUNT(*) AS keyword_cnt
    FROM movie_keyword mk
    JOIN title t
        ON mk.movie_id = t.id
    WHERE t.production_year IS NOT NULL
    GROUP BY t.production_year, mk.keyword_id
),
ranked_keywords AS (
    SELECT
        production_year,
        keyword_id,
        keyword_cnt,
        ROW_NUMBER() OVER (PARTITION BY production_year ORDER BY keyword_cnt DESC) AS rk
    FROM keyword_by_year
)
SELECT
    production_year,
    keyword_id,
    keyword_cnt
FROM ranked_keywords
WHERE rk <= 5
ORDER BY production_year, keyword_cnt DESC

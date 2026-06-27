WITH movie_keyword_counts AS (
    SELECT
        mk.movie_id,
        COUNT(DISTINCT mk.keyword_id) AS kw_cnt
    FROM movie_keyword mk
    GROUP BY mk.movie_id
)
SELECT
    t.production_year,
    COUNT(DISTINCT t.id) AS movie_count,
    COUNT(DISTINCT mc.company_id) AS production_company_count,
    AVG(mkc.kw_cnt) AS avg_keywords_per_movie
FROM title t
LEFT JOIN movie_companies mc
    ON mc.movie_id = t.id
    AND mc.company_type_id = 1
LEFT JOIN movie_keyword_counts mkc
    ON mkc.movie_id = t.id
WHERE t.production_year IS NOT NULL
GROUP BY t.production_year
ORDER BY t.production_year

WITH movie_keyword_counts AS (
    SELECT
        mk.movie_id,
        COUNT(DISTINCT mk.keyword_id) AS keyword_cnt
    FROM movie_keyword mk
    GROUP BY mk.movie_id
)
SELECT
    cn.country_code,
    ct.kind AS company_type,
    t.production_year,
    COUNT(DISTINCT t.id) AS num_movies,
    SUM(COALESCE(mkc.keyword_cnt, 0)) AS total_distinct_keywords_per_movie,
    AVG(COALESCE(mkc.keyword_cnt, 0)) AS avg_distinct_keywords_per_movie
FROM movie_companies mc
JOIN title t
    ON mc.movie_id = t.id
JOIN company_name cn
    ON mc.company_id = cn.id
JOIN company_type ct
    ON mc.company_type_id = ct.id
LEFT JOIN movie_keyword_counts mkc
    ON t.id = mkc.movie_id
WHERE t.production_year IS NOT NULL
GROUP BY cn.country_code, ct.kind, t.production_year
HAVING COUNT(DISTINCT t.id) >= 5
ORDER BY num_movies DESC, cn.country_code, ct.kind, t.production_year

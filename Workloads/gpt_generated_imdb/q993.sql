WITH movie_keyword_counts AS (
    SELECT
        mk.movie_id,
        COUNT(DISTINCT mk.keyword_id) AS keyword_cnt
    FROM movie_keyword mk
    GROUP BY mk.movie_id
)
SELECT
    ct.kind AS company_type,
    kt.kind AS title_kind,
    COUNT(DISTINCT t.id) AS num_movies,
    SUM(COALESCE(mkc.keyword_cnt, 0)) AS total_keywords,
    AVG(COALESCE(mkc.keyword_cnt, 0)) AS avg_keywords_per_movie,
    COUNT(DISTINCT cn.id) AS num_companies
FROM movie_companies mc
JOIN title t
    ON mc.movie_id = t.id
JOIN company_type ct
    ON mc.company_type_id = ct.id
JOIN company_name cn
    ON mc.company_id = cn.id
JOIN kind_type kt
    ON t.kind_id = kt.id
LEFT JOIN movie_keyword_counts mkc
    ON t.id = mkc.movie_id
WHERE t.production_year >= 2000
GROUP BY ct.kind, kt.kind
ORDER BY num_movies DESC, avg_keywords_per_movie DESC

WITH movie_keyword_counts AS (
    SELECT
        mk.movie_id,
        COUNT(DISTINCT mk.keyword_id) AS kw_count
    FROM movie_keyword mk
    GROUP BY mk.movie_id
)
SELECT
    cn.name AS company_name,
    kt.kind AS movie_kind,
    COUNT(DISTINCT t.id) AS movie_count,
    SUM(COALESCE(mkc.kw_count, 0)) AS total_keywords,
    AVG(COALESCE(mkc.kw_count, 0)) AS avg_keywords_per_movie
FROM movie_companies mc
JOIN title t
    ON mc.movie_id = t.id
JOIN company_name cn
    ON mc.company_id = cn.id
JOIN company_type ct
    ON mc.company_type_id = ct.id
JOIN kind_type kt
    ON t.kind_id = kt.id
LEFT JOIN movie_keyword_counts mkc
    ON t.id = mkc.movie_id
WHERE ct.kind = 'production company'
GROUP BY cn.name, kt.kind
ORDER BY movie_count DESC
LIMIT 10

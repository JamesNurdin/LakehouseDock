WITH per_movie_stats AS (
    SELECT
        t.id AS movie_id,
        COUNT(DISTINCT ci.person_id) AS cast_cnt,
        COUNT(DISTINCT mc.company_id) AS company_cnt,
        COUNT(DISTINCT mk.keyword_id) AS keyword_cnt
    FROM title t
    LEFT JOIN cast_info ci ON ci.movie_id = t.id
    LEFT JOIN movie_companies mc ON mc.movie_id = t.id
    LEFT JOIN movie_keyword mk ON mk.movie_id = t.id
    GROUP BY t.id
)
SELECT
    t.production_year,
    kt.kind,
    COUNT(*) AS movie_cnt,
    AVG(pms.cast_cnt) AS avg_cast_per_movie,
    AVG(pms.company_cnt) AS avg_companies_per_movie,
    AVG(pms.keyword_cnt) AS avg_keywords_per_movie
FROM per_movie_stats pms
JOIN title t ON t.id = pms.movie_id
JOIN kind_type kt ON t.kind_id = kt.id
WHERE t.production_year >= 2000
GROUP BY t.production_year, kt.kind
ORDER BY t.production_year DESC, kt.kind

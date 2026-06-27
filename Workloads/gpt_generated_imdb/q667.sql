WITH keyword_counts AS (
    SELECT
        mk.movie_id,
        COUNT(DISTINCT mk.keyword_id) AS keyword_cnt
    FROM movie_keyword mk
    GROUP BY mk.movie_id
),
movie_company_keyword AS (
    SELECT
        mc.movie_id,
        mc.company_type_id,
        COALESCE(kc.keyword_cnt, 0) AS keyword_cnt
    FROM movie_companies mc
    JOIN title t ON mc.movie_id = t.id
    LEFT JOIN keyword_counts kc ON mc.movie_id = kc.movie_id
    WHERE t.production_year >= 2000
    GROUP BY mc.movie_id, mc.company_type_id, COALESCE(kc.keyword_cnt, 0)
)
SELECT
    mck.company_type_id,
    COUNT(DISTINCT mck.movie_id) AS movie_cnt,
    AVG(mck.keyword_cnt) AS avg_keywords_per_movie
FROM movie_company_keyword mck
GROUP BY mck.company_type_id
ORDER BY movie_cnt DESC
LIMIT 10

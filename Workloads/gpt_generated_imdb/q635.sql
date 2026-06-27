WITH movie_cast_counts AS (
    SELECT
        ci.movie_id,
        COUNT(DISTINCT ci.person_id) AS cast_count
    FROM cast_info ci
    GROUP BY ci.movie_id
),
movie_keyword_counts AS (
    SELECT
        mk.movie_id,
        COUNT(DISTINCT mk.keyword_id) AS keyword_count
    FROM movie_keyword mk
    GROUP BY mk.movie_id
),
movie_stats AS (
    SELECT
        t.id AS movie_id,
        t.title,
        t.production_year,
        kt.kind AS kind,
        COALESCE(cc.cast_count, 0) AS cast_count,
        COALESCE(kc.keyword_count, 0) AS keyword_count
    FROM title t
    JOIN kind_type kt ON t.kind_id = kt.id
    LEFT JOIN movie_cast_counts cc ON t.id = cc.movie_id
    LEFT JOIN movie_keyword_counts kc ON t.id = kc.movie_id
    WHERE kt.kind = 'movie'
      AND t.production_year IS NOT NULL
)
SELECT
    cn.name AS production_company,
    ms.production_year,
    COUNT(DISTINCT ms.movie_id) AS movie_count,
    AVG(ms.cast_count) AS avg_cast_per_movie,
    AVG(ms.keyword_count) AS avg_keywords_per_movie
FROM movie_stats ms
JOIN movie_companies mc ON ms.movie_id = mc.movie_id
JOIN company_name cn ON mc.company_id = cn.id
JOIN company_type ct ON mc.company_type_id = ct.id
WHERE ct.kind = 'production company'
GROUP BY cn.name, ms.production_year
ORDER BY movie_count DESC
LIMIT 20

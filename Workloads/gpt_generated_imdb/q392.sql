WITH keyword_counts AS (
    SELECT
        movie_id,
        COUNT(*) AS keyword_cnt
    FROM movie_keyword
    GROUP BY movie_id
),
company_stats AS (
    SELECT
        ct.kind AS company_type,
        cn.name AS company_name,
        COUNT(DISTINCT t.id) AS movie_count,
        SUM(COALESCE(kc.keyword_cnt, 0)) AS total_keywords
    FROM movie_companies mc
    JOIN title t
        ON mc.movie_id = t.id
    JOIN kind_type kt
        ON t.kind_id = kt.id
    JOIN company_name cn
        ON mc.company_id = cn.id
    JOIN company_type ct
        ON mc.company_type_id = ct.id
    LEFT JOIN keyword_counts kc
        ON t.id = kc.movie_id
    WHERE kt.kind = 'movie' AND t.production_year >= 2000
    GROUP BY ct.kind, cn.name
)
SELECT
    company_type,
    company_name,
    movie_count,
    total_keywords,
    total_keywords / movie_count AS avg_keywords_per_movie
FROM (
    SELECT
        cs.*,
        ROW_NUMBER() OVER (PARTITION BY cs.company_type ORDER BY cs.movie_count DESC) AS rn
    FROM company_stats cs
) ranked
WHERE rn <= 5
ORDER BY company_type, movie_count DESC

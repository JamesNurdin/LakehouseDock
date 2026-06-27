WITH movie_stats AS (
    SELECT
        t.id AS movie_id,
        t.title,
        kt.kind,
        COUNT(DISTINCT mk.keyword_id) AS keyword_cnt,
        COUNT(DISTINCT ci.person_id) AS cast_cnt,
        COUNT(DISTINCT mc.company_id) AS company_cnt
    FROM title t
    JOIN kind_type kt ON t.kind_id = kt.id
    LEFT JOIN movie_keyword mk ON mk.movie_id = t.id
    LEFT JOIN cast_info ci ON ci.movie_id = t.id
    LEFT JOIN movie_companies mc ON mc.movie_id = t.id
    GROUP BY t.id, t.title, kt.kind
)
SELECT
    kind,
    COUNT(*) AS total_movies,
    AVG(keyword_cnt) AS avg_keywords_per_movie,
    AVG(cast_cnt) AS avg_cast_per_movie,
    AVG(company_cnt) AS avg_companies_per_movie
FROM movie_stats
GROUP BY kind
ORDER BY total_movies DESC
LIMIT 10

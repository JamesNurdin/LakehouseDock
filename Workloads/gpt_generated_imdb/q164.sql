WITH movie_metrics AS (
    SELECT
        t.id,
        COUNT(DISTINCT ci.person_id) AS cast_count,
        COUNT(DISTINCT mk.keyword_id) AS keyword_count
    FROM title t
    JOIN kind_type kt ON t.kind_id = kt.id
    LEFT JOIN cast_info ci ON ci.movie_id = t.id
    LEFT JOIN movie_keyword mk ON mk.movie_id = t.id
    WHERE kt.kind = 'movie' AND t.production_year >= 2000
    GROUP BY t.id
)
SELECT
    ct.kind AS company_type,
    COUNT(DISTINCT mc.movie_id) AS distinct_movies,
    AVG(mm.cast_count) AS avg_cast_per_movie,
    AVG(mm.keyword_count) AS avg_keywords_per_movie
FROM movie_companies mc
JOIN company_type ct ON mc.company_type_id = ct.id
JOIN movie_metrics mm ON mm.id = mc.movie_id
GROUP BY ct.kind
ORDER BY distinct_movies DESC

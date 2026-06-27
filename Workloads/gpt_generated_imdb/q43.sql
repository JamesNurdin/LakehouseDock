WITH movie_stats AS (
    SELECT
        t.id AS movie_id,
        t.title,
        t.production_year,
        kt.kind AS kind,
        COUNT(DISTINCT ci.person_id) AS cast_count,
        COUNT(DISTINCT mc.company_id) AS company_count,
        COUNT(DISTINCT mk.keyword_id) AS keyword_count,
        COUNT(DISTINCT mi.info_type_id) AS info_type_count
    FROM title t
    JOIN kind_type kt ON t.kind_id = kt.id
    LEFT JOIN cast_info ci ON ci.movie_id = t.id
    LEFT JOIN movie_companies mc ON mc.movie_id = t.id
    LEFT JOIN movie_keyword mk ON mk.movie_id = t.id
    LEFT JOIN movie_info_idx mi ON mi.movie_id = t.id
    GROUP BY t.id, t.title, t.production_year, kt.kind
)
SELECT
    movie_stats.kind,
    COUNT(*) AS movie_count,
    AVG(movie_stats.cast_count) AS avg_cast_per_movie,
    AVG(movie_stats.company_count) AS avg_companies_per_movie,
    AVG(movie_stats.keyword_count) AS avg_keywords_per_movie,
    AVG(movie_stats.info_type_count) AS avg_info_type_count_per_movie
FROM movie_stats
WHERE movie_stats.production_year >= 2000
GROUP BY movie_stats.kind
ORDER BY movie_count DESC
LIMIT 10

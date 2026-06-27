WITH movie_details AS (
    SELECT
        t.id AS movie_id,
        t.title,
        CAST(t.production_year AS integer) AS production_year,
        COUNT(DISTINCT ci.person_id) AS cast_count,
        COUNT(DISTINCT mk.keyword_id) AS keyword_count
    FROM title t
    JOIN kind_type kt ON t.kind_id = kt.id
    LEFT JOIN cast_info ci ON ci.movie_id = t.id
    LEFT JOIN movie_keyword mk ON mk.movie_id = t.id
    WHERE kt.kind = 'movie' AND t.production_year IS NOT NULL
    GROUP BY t.id, t.title, CAST(t.production_year AS integer)
)
SELECT
    md.production_year,
    COUNT(*) AS num_movies,
    SUM(md.cast_count) AS total_cast_members,
    AVG(md.cast_count) AS avg_cast_per_movie,
    SUM(md.keyword_count) AS total_keywords,
    AVG(md.keyword_count) AS avg_keywords_per_movie
FROM movie_details md
GROUP BY md.production_year
ORDER BY md.production_year

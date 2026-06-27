WITH movie_cast AS (
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
movie_details AS (
    SELECT
        t.id AS movie_id,
        t.title,
        t.production_year,
        COALESCE(mc.cast_count, 0) AS cast_count,
        COALESCE(mk.keyword_count, 0) AS keyword_count
    FROM title t
    JOIN kind_type kt ON t.kind_id = kt.id
    LEFT JOIN movie_cast mc ON mc.movie_id = t.id
    LEFT JOIN movie_keyword_counts mk ON mk.movie_id = t.id
    WHERE kt.kind = 'movie'
)
SELECT
    md.production_year,
    COUNT(md.movie_id) AS movie_count,
    AVG(md.cast_count) AS avg_cast_per_movie,
    AVG(md.keyword_count) AS avg_keywords_per_movie
FROM movie_details md
GROUP BY md.production_year
ORDER BY md.production_year

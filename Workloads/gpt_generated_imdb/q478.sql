WITH cast_counts AS (
    SELECT
        movie_id,
        COUNT(DISTINCT person_id) AS cast_member_count
    FROM cast_info
    GROUP BY movie_id
),
keyword_movies AS (
    SELECT
        mk.movie_id,
        k.keyword
    FROM movie_keyword mk
    JOIN keyword k
        ON mk.keyword_id = k.id
),
movie_details AS (
    SELECT
        t.id AS movie_id,
        t.title,
        t.production_year
    FROM title t
    WHERE t.production_year IS NOT NULL
)
SELECT
    km.keyword,
    COUNT(DISTINCT md.movie_id) AS total_movies,
    SUM(cc.cast_member_count) AS total_cast_members,
    CAST(SUM(cc.cast_member_count) AS DOUBLE) / COUNT(DISTINCT md.movie_id) AS avg_cast_per_movie,
    MIN(md.production_year) AS earliest_year,
    MAX(md.production_year) AS latest_year
FROM keyword_movies km
JOIN movie_details md
    ON km.movie_id = md.movie_id
JOIN cast_counts cc
    ON md.movie_id = cc.movie_id
GROUP BY km.keyword
ORDER BY total_movies DESC
LIMIT 20

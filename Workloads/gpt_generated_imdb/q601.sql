WITH
    movie_cast AS (
        SELECT
            t.id AS movie_id,
            COUNT(DISTINCT ci.person_id) AS cast_count
        FROM
            title t
            JOIN cast_info ci ON ci.movie_id = t.id
        GROUP BY
            t.id
    ),
    movie_keywords AS (
        SELECT
            t.id AS movie_id,
            COUNT(DISTINCT mk.keyword_id) AS keyword_count
        FROM
            title t
            JOIN movie_keyword mk ON mk.movie_id = t.id
        GROUP BY
            t.id
    ),
    movie_stats AS (
        SELECT
            t.id,
            t.title,
            kt.kind AS kind,
            COALESCE(mc.cast_count, 0) AS cast_count,
            COALESCE(mk.keyword_count, 0) AS keyword_count
        FROM
            title t
            JOIN kind_type kt ON t.kind_id = kt.id
            LEFT JOIN movie_cast mc ON mc.movie_id = t.id
            LEFT JOIN movie_keywords mk ON mk.movie_id = t.id
    )
SELECT
    ms.kind,
    COUNT(*) AS movie_count,
    AVG(ms.cast_count) AS avg_cast_per_movie,
    AVG(ms.keyword_count) AS avg_keywords_per_movie
FROM
    movie_stats ms
GROUP BY
    ms.kind
ORDER BY
    avg_cast_per_movie DESC

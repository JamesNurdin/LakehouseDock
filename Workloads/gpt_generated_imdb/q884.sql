WITH movies AS (
    SELECT
        t.id AS movie_id,
        kt.kind AS genre
    FROM title t
    JOIN kind_type kt ON t.kind_id = kt.id
    WHERE t.production_year BETWEEN 2000 AND 2020
),

movie_keyword_counts AS (
    SELECT
        m.movie_id,
        m.genre,
        COUNT(DISTINCT kw.id) AS num_keywords
    FROM movies m
    LEFT JOIN movie_keyword mk ON mk.movie_id = m.movie_id
    LEFT JOIN keyword kw ON kw.id = mk.keyword_id
    GROUP BY m.movie_id, m.genre
),

movie_cast_counts AS (
    SELECT
        m.movie_id,
        m.genre,
        COUNT(DISTINCT ci.person_id) AS num_cast
    FROM movies m
    LEFT JOIN cast_info ci ON ci.movie_id = m.movie_id
    GROUP BY m.movie_id, m.genre
),

movie_agg AS (
    SELECT
        mkc.movie_id,
        mkc.genre,
        COALESCE(mkc.num_keywords, 0) AS num_keywords,
        COALESCE(mcc.num_cast, 0) AS num_cast
    FROM movie_keyword_counts mkc
    LEFT JOIN movie_cast_counts mcc
        ON mkc.movie_id = mcc.movie_id AND mkc.genre = mcc.genre
),

genre_stats AS (
    SELECT
        genre,
        COUNT(DISTINCT movie_id) AS num_movies,
        AVG(num_keywords) AS avg_keywords_per_movie,
        AVG(num_cast) AS avg_cast_per_movie
    FROM movie_agg
    GROUP BY genre
),

keyword_popularity AS (
    SELECT
        m.genre,
        kw.keyword,
        COUNT(DISTINCT mk.movie_id) AS movies_with_keyword,
        ROW_NUMBER() OVER (PARTITION BY m.genre ORDER BY COUNT(DISTINCT mk.movie_id) DESC) AS rk
    FROM movies m
    JOIN movie_keyword mk ON mk.movie_id = m.movie_id
    JOIN keyword kw ON kw.id = mk.keyword_id
    GROUP BY m.genre, kw.keyword
)

SELECT
    gs.genre,
    gs.num_movies,
    ROUND(gs.avg_keywords_per_movie, 2) AS avg_keywords_per_movie,
    ROUND(gs.avg_cast_per_movie, 2) AS avg_cast_per_movie,
    kp.keyword,
    kp.movies_with_keyword
FROM genre_stats gs
JOIN keyword_popularity kp
    ON kp.genre = gs.genre
WHERE kp.rk <= 3
ORDER BY gs.genre, kp.movies_with_keyword DESC

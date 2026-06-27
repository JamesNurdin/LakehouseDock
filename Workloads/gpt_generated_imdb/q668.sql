WITH genre_movies AS (
    SELECT
        t.id AS movie_id,
        mi.info AS genre
    FROM title t
    JOIN kind_type kt ON t.kind_id = kt.id
    JOIN movie_info mi ON mi.movie_id = t.id
    JOIN info_type it ON mi.info_type_id = it.id
    WHERE kt.kind = 'movie'
      AND it.info = 'genres'
),
movie_keywords AS (
    SELECT
        gm.genre,
        k.keyword,
        COUNT(DISTINCT gm.movie_id) AS movie_cnt
    FROM genre_movies gm
    JOIN movie_keyword mk ON mk.movie_id = gm.movie_id
    JOIN keyword k ON mk.keyword_id = k.id
    GROUP BY gm.genre, k.keyword
),
ranked_keywords AS (
    SELECT
        genre,
        keyword,
        movie_cnt,
        ROW_NUMBER() OVER (PARTITION BY genre ORDER BY movie_cnt DESC) AS rn
    FROM movie_keywords
)
SELECT
    genre,
    keyword,
    movie_cnt
FROM ranked_keywords
WHERE rn <= 5
ORDER BY genre, movie_cnt DESC

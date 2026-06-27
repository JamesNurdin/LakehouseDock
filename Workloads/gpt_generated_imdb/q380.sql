WITH genre_movie_stats AS (
    SELECT
        t.id AS movie_id,
        kt.kind AS genre,
        t.title,
        mi.info AS rating
    FROM title t
    JOIN kind_type kt ON t.kind_id = kt.id
    LEFT JOIN movie_info mi ON mi.movie_id = t.id
    LEFT JOIN info_type it ON mi.info_type_id = it.id AND it.info = 'rating'
),
genre_cast_counts AS (
    SELECT
        kt.kind AS genre,
        COUNT(DISTINCT ci.person_id) AS distinct_cast
    FROM cast_info ci
    JOIN title t ON ci.movie_id = t.id
    JOIN kind_type kt ON t.kind_id = kt.id
    GROUP BY kt.kind
),
genre_keyword_counts AS (
    SELECT
        kt.kind AS genre,
        k.keyword,
        COUNT(*) AS keyword_count
    FROM movie_keyword mk
    JOIN title t ON mk.movie_id = t.id
    JOIN kind_type kt ON t.kind_id = kt.id
    JOIN keyword k ON mk.keyword_id = k.id
    GROUP BY kt.kind, k.keyword
),
genre_top_keyword AS (
    SELECT
        genre,
        keyword,
        keyword_count,
        ROW_NUMBER() OVER (PARTITION BY genre ORDER BY keyword_count DESC) AS rn
    FROM genre_keyword_counts
)
SELECT
    gm.genre,
    COUNT(*) AS num_movies,
    AVG(CAST(gm.rating AS double)) AS avg_rating,
    cc.distinct_cast,
    tk.keyword AS top_keyword,
    tk.keyword_count AS top_keyword_count
FROM genre_movie_stats gm
JOIN genre_cast_counts cc ON gm.genre = cc.genre
LEFT JOIN genre_top_keyword tk ON gm.genre = tk.genre AND tk.rn = 1
GROUP BY gm.genre, cc.distinct_cast, tk.keyword, tk.keyword_count
ORDER BY avg_rating DESC
LIMIT 10

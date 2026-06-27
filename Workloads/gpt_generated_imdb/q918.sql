WITH movie_cast_counts AS (
    SELECT
        t.id AS title_id,
        t.title,
        k.kind,
        COUNT(DISTINCT ci.person_id) AS cast_count
    FROM title t
    JOIN kind_type k ON t.kind_id = k.id
    JOIN cast_info ci ON ci.movie_id = t.id
    GROUP BY t.id, t.title, k.kind
),
movie_keyword_counts AS (
    SELECT
        t.id AS title_id,
        COUNT(DISTINCT mk.keyword_id) AS keyword_count
    FROM title t
    JOIN movie_keyword mk ON mk.movie_id = t.id
    GROUP BY t.id
),
movie_genre_counts AS (
    SELECT
        t.id AS title_id,
        COUNT(DISTINCT mi.info) AS genre_count
    FROM title t
    JOIN movie_info mi ON mi.movie_id = t.id
    JOIN info_type it ON mi.info_type_id = it.id
    WHERE it.info = 'genre'
    GROUP BY t.id
)
SELECT
    mc.title,
    mc.kind,
    mc.cast_count,
    COALESCE(mk.keyword_count, 0) AS keyword_count,
    COALESCE(mg.genre_count, 0) AS genre_count
FROM movie_cast_counts mc
LEFT JOIN movie_keyword_counts mk ON mk.title_id = mc.title_id
LEFT JOIN movie_genre_counts mg ON mg.title_id = mc.title_id
ORDER BY mc.cast_count DESC
LIMIT 10

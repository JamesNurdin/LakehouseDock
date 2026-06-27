WITH rating_agg AS (
    SELECT
        mi.movie_id,
        AVG(CAST(mi.info AS DOUBLE)) AS avg_rating
    FROM movie_info mi
    JOIN info_type it
        ON mi.info_type_id = it.id
    WHERE it.info = 'rating'
    GROUP BY mi.movie_id
),
female_cast AS (
    SELECT
        ci.movie_id,
        COUNT(DISTINCT ci.person_id) AS female_cast_count
    FROM cast_info ci
    JOIN name n
        ON ci.person_id = n.id
    WHERE n.gender = 'F'
    GROUP BY ci.movie_id
),
keyword_counts AS (
    SELECT
        mk.movie_id,
        COUNT(DISTINCT mk.keyword_id) AS keyword_count
    FROM movie_keyword mk
    GROUP BY mk.movie_id
)
SELECT
    t.title,
    t.production_year,
    COALESCE(fc.female_cast_count, 0) AS female_cast_count,
    ROUND(r.avg_rating, 2) AS avg_rating,
    COALESCE(kc.keyword_count, 0) AS keyword_count
FROM title t
LEFT JOIN female_cast fc
    ON t.id = fc.movie_id
LEFT JOIN rating_agg r
    ON t.id = r.movie_id
LEFT JOIN keyword_counts kc
    ON t.id = kc.movie_id
WHERE t.kind_id = 1
ORDER BY female_cast_count DESC, avg_rating DESC
LIMIT 10

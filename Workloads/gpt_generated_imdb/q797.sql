WITH movie_cast_counts AS (
    SELECT
        t.id AS title_id,
        t.title,
        t.production_year,
        kt.kind,
        COUNT(DISTINCT ci.person_id) AS cast_count
    FROM title t
    JOIN kind_type kt ON t.kind_id = kt.id
    LEFT JOIN cast_info ci ON ci.movie_id = t.id
    WHERE t.production_year >= 2000
    GROUP BY t.id, t.title, t.production_year, kt.kind
),
movie_keyword_counts AS (
    SELECT
        t.id AS title_id,
        COUNT(DISTINCT kw.id) AS keyword_count
    FROM title t
    LEFT JOIN movie_keyword mk ON mk.movie_id = t.id
    LEFT JOIN keyword kw ON mk.keyword_id = kw.id
    WHERE t.production_year >= 2000
    GROUP BY t.id
)
SELECT
    mc.title,
    mc.production_year,
    mc.kind,
    mc.cast_count,
    mkc.keyword_count,
    mc.cast_count * mkc.keyword_count AS cast_keyword_product
FROM movie_cast_counts mc
JOIN movie_keyword_counts mkc ON mkc.title_id = mc.title_id
ORDER BY cast_keyword_product DESC
LIMIT 10

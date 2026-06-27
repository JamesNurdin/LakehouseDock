WITH movie_cast_counts AS (
    SELECT
        t.id AS movie_id,
        t.title,
        t.production_year,
        kt.kind,
        COUNT(DISTINCT ci.person_id) AS distinct_cast_count
    FROM title t
    JOIN kind_type kt ON t.kind_id = kt.id
    JOIN cast_info ci ON ci.movie_id = t.id
    WHERE t.production_year BETWEEN 2000 AND 2020
      AND kt.kind = 'movie'
    GROUP BY t.id, t.title, t.production_year, kt.kind
),
movie_keyword_counts AS (
    SELECT
        t.id AS movie_id,
        COUNT(DISTINCT k.id) AS distinct_keyword_count
    FROM title t
    JOIN movie_keyword mk ON mk.movie_id = t.id
    JOIN keyword k ON mk.keyword_id = k.id
    GROUP BY t.id
)
SELECT
    mc.title,
    mc.production_year,
    mc.kind,
    mc.distinct_cast_count,
    COALESCE(kc.distinct_keyword_count, 0) AS distinct_keyword_count
FROM movie_cast_counts mc
LEFT JOIN movie_keyword_counts kc ON mc.movie_id = kc.movie_id
ORDER BY mc.distinct_cast_count DESC, mc.production_year DESC
LIMIT 10

WITH movie_cast_counts AS (
    SELECT
        t.id AS movie_id,
        t.title,
        t.production_year,
        kt.kind,
        COUNT(DISTINCT ci.person_id) AS cast_count
    FROM title t
    JOIN kind_type kt ON t.kind_id = kt.id
    JOIN cast_info ci ON ci.movie_id = t.id
    WHERE kt.kind = 'movie'
      AND t.production_year IS NOT NULL
    GROUP BY t.id, t.title, t.production_year, kt.kind
),
movie_keyword_counts AS (
    SELECT
        mk.movie_id,
        COUNT(DISTINCT mk.keyword_id) AS keyword_count
    FROM movie_keyword mk
    GROUP BY mk.movie_id
),
movie_counts AS (
    SELECT
        mc.movie_id,
        mc.title,
        mc.production_year,
        mc.kind,
        mc.cast_count,
        COALESCE(mk.keyword_count, 0) AS keyword_count,
        ROW_NUMBER() OVER (PARTITION BY mc.production_year ORDER BY mc.cast_count DESC) AS rn
    FROM movie_cast_counts mc
    LEFT JOIN movie_keyword_counts mk ON mk.movie_id = mc.movie_id
)
SELECT
    title,
    production_year,
    kind,
    cast_count,
    keyword_count
FROM movie_counts
WHERE rn <= 3
ORDER BY production_year, cast_count DESC

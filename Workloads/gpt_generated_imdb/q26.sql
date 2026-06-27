WITH movie_agg AS (
    SELECT
        t.id AS movie_id,
        t.production_year,
        kt.kind,
        COUNT(DISTINCT ci.person_id) AS cast_count,
        COUNT(DISTINCT mk.keyword_id) AS keyword_count
    FROM title t
    JOIN kind_type kt ON t.kind_id = kt.id
    LEFT JOIN cast_info ci ON ci.movie_id = t.id
    LEFT JOIN movie_keyword mk ON mk.movie_id = t.id
    WHERE t.production_year IS NOT NULL
    GROUP BY t.id, t.production_year, kt.kind
)
SELECT
    production_year,
    kind,
    COUNT(*) AS movie_count,
    AVG(cast_count) AS avg_cast_per_movie,
    AVG(keyword_count) AS avg_keywords_per_movie
FROM movie_agg
GROUP BY production_year, kind
ORDER BY production_year, kind

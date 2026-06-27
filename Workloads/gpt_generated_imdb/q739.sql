WITH keyword_counts AS (
    SELECT
        movie_id,
        COUNT(DISTINCT keyword_id) AS keyword_cnt
    FROM movie_keyword
    GROUP BY movie_id
),
actor_counts AS (
    SELECT
        movie_id,
        COUNT(DISTINCT person_id) AS actor_cnt
    FROM cast_info
    GROUP BY movie_id
),
movie_stats AS (
    SELECT
        t.id AS movie_id,
        t.title,
        t.production_year,
        kt.kind AS kind,
        COALESCE(kc.keyword_cnt, 0) AS keyword_cnt,
        COALESCE(ac.actor_cnt, 0) AS actor_cnt
    FROM title t
    JOIN kind_type kt ON t.kind_id = kt.id
    LEFT JOIN keyword_counts kc ON kc.movie_id = t.id
    LEFT JOIN actor_counts ac ON ac.movie_id = t.id
    WHERE t.production_year >= 2000
)
SELECT
    ms.production_year,
    ms.kind,
    COUNT(*) AS movie_count,
    SUM(ms.keyword_cnt) AS total_keyword_assignments,
    SUM(ms.actor_cnt) AS total_actor_assignments,
    ROUND(CAST(SUM(ms.keyword_cnt) AS DOUBLE) / COUNT(*), 2) AS avg_keywords_per_movie,
    ROUND(CAST(SUM(ms.actor_cnt) AS DOUBLE) / COUNT(*), 2) AS avg_actors_per_movie
FROM movie_stats ms
GROUP BY ms.production_year, ms.kind
ORDER BY ms.production_year DESC, ms.kind

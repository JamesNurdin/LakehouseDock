WITH actor_movie_keyword_counts AS (
    SELECT
        ci.person_id,
        ci.movie_id,
        COUNT(DISTINCT mk.keyword_id) AS distinct_keyword_cnt
    FROM cast_info ci
    JOIN title t
        ON ci.movie_id = t.id
    JOIN kind_type kt
        ON t.kind_id = kt.id
    JOIN movie_keyword mk
        ON t.id = mk.movie_id
    WHERE kt.kind = 'movie'
      AND t.production_year >= 2015
    GROUP BY ci.person_id, ci.movie_id
),
actor_aggregates AS (
    SELECT
        amkc.person_id,
        COUNT(*) AS movie_count,
        AVG(amkc.distinct_keyword_cnt) AS avg_distinct_keywords_per_movie
    FROM actor_movie_keyword_counts amkc
    GROUP BY amkc.person_id
)
SELECT
    n.id AS actor_id,
    n.name AS actor_name,
    aa.movie_count,
    aa.avg_distinct_keywords_per_movie
FROM actor_aggregates aa
JOIN name n
    ON aa.person_id = n.id
ORDER BY aa.avg_distinct_keywords_per_movie DESC, aa.movie_count DESC
LIMIT 10

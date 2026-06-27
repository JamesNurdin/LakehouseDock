WITH movies AS (
    SELECT t.id,
           t.production_year
    FROM title t
    JOIN kind_type kt ON t.kind_id = kt.id
    WHERE kt.kind = 'movie'
),
actor_movie_keywords AS (
    SELECT DISTINCT ci.person_id,
                    ci.movie_id,
                    mk.keyword_id
    FROM cast_info ci
    JOIN movies m ON ci.movie_id = m.id
    JOIN movie_keyword mk ON ci.movie_id = mk.movie_id
),
actor_stats AS (
    SELECT ci.person_id,
           n.name AS actor_name,
           n.gender,
           COUNT(DISTINCT ci.movie_id)                         AS movie_count,
           AVG(m.production_year)                              AS avg_production_year,
           COUNT(DISTINCT cn.id)                               AS distinct_characters,
           COUNT(DISTINCT amk.keyword_id)                     AS total_distinct_keywords
    FROM cast_info ci
    JOIN name n ON ci.person_id = n.id
    JOIN movies m ON ci.movie_id = m.id
    LEFT JOIN char_name cn ON ci.person_role_id = cn.id
    LEFT JOIN actor_movie_keywords amk
           ON ci.person_id = amk.person_id
          AND ci.movie_id = amk.movie_id
    GROUP BY ci.person_id, n.name, n.gender
)
SELECT person_id,
       actor_name,
       gender,
       movie_count,
       avg_production_year,
       distinct_characters,
       CASE WHEN movie_count > 0 THEN total_distinct_keywords / movie_count ELSE 0 END AS avg_keywords_per_movie
FROM actor_stats
ORDER BY movie_count DESC,
         avg_production_year DESC
LIMIT 10

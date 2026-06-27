WITH
    actor_movies AS (
        SELECT DISTINCT ci.person_id, ci.movie_id
        FROM cast_info ci
    ),
    rating_per_movie AS (
        SELECT mi.movie_id,
               CAST(mi.info AS DOUBLE) AS rating
        FROM movie_info mi
        JOIN info_type it
          ON mi.info_type_id = it.id
        WHERE it.info = 'rating'
    ),
    actor_movie_stats AS (
        SELECT
            n.id AS person_id,
            n.name,
            n.gender,
            COUNT(am.movie_id) AS movie_count,
            MIN(t.production_year) AS first_year,
            MAX(t.production_year) AS last_year,
            AVG(mr.rating) AS avg_rating
        FROM actor_movies am
        JOIN name n
          ON am.person_id = n.id
        JOIN title t
          ON am.movie_id = t.id
        LEFT JOIN rating_per_movie mr
          ON mr.movie_id = t.id
        WHERE t.production_year >= 2000
        GROUP BY n.id, n.name, n.gender
    ),
    char_counts AS (
        SELECT
            ci.person_id,
            COUNT(DISTINCT cn.name) AS distinct_characters
        FROM cast_info ci
        JOIN title t
          ON ci.movie_id = t.id
        LEFT JOIN char_name cn
          ON ci.person_role_id = cn.id
        WHERE t.production_year >= 2000
        GROUP BY ci.person_id
    ),
    aka_counts AS (
        SELECT
            a.person_id,
            COUNT(DISTINCT a.name) AS aka_count
        FROM aka_name a
        GROUP BY a.person_id
    )
SELECT
    ams.person_id,
    ams.name,
    ams.gender,
    ams.movie_count,
    ams.first_year,
    ams.last_year,
    ROUND(ams.avg_rating, 2) AS avg_rating,
    COALESCE(cc.distinct_characters, 0) AS distinct_characters,
    COALESCE(ac.aka_count, 0) AS aka_count
FROM actor_movie_stats ams
LEFT JOIN char_counts cc
  ON ams.person_id = cc.person_id
LEFT JOIN aka_counts ac
  ON ams.person_id = ac.person_id
ORDER BY ams.movie_count DESC
LIMIT 10

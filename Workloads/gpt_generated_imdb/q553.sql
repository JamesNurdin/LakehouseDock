WITH movies_filtered AS (
    SELECT t.id AS movie_id,
           t.title,
           t.production_year
    FROM title t
    JOIN kind_type kt ON t.kind_id = kt.id
    WHERE kt.kind = 'movie'
      AND t.production_year >= 2000
),
keywords AS (
    SELECT mi.movie_id,
           mi.info AS keyword
    FROM movie_info mi
    JOIN info_type it ON mi.info_type_id = it.id
    WHERE it.info = 'keyword'
),
actor_counts AS (
    SELECT ci.movie_id,
           n.gender,
           COUNT(DISTINCT ci.person_id) AS gender_actor_cnt
    FROM cast_info ci
    JOIN name n ON ci.person_id = n.id
    GROUP BY ci.movie_id, n.gender
)
SELECT
    k.keyword,
    COUNT(DISTINCT k.movie_id) AS movie_cnt,
    SUM(ac.gender_actor_cnt) AS total_actor_cnt,
    SUM(CASE WHEN ac.gender = 'M' THEN ac.gender_actor_cnt ELSE 0 END) AS male_actor_cnt,
    SUM(CASE WHEN ac.gender = 'F' THEN ac.gender_actor_cnt ELSE 0 END) AS female_actor_cnt,
    SUM(ac.gender_actor_cnt) / COUNT(DISTINCT k.movie_id) AS avg_actor_cnt_per_movie
FROM keywords k
JOIN movies_filtered mf ON k.movie_id = mf.movie_id
LEFT JOIN actor_counts ac ON ac.movie_id = mf.movie_id
GROUP BY k.keyword
ORDER BY movie_cnt DESC
LIMIT 10

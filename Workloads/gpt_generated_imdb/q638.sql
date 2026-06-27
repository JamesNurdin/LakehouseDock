WITH
    actor_counts AS (
        SELECT ci.movie_id AS movie_id,
               COUNT(DISTINCT ci.person_id) AS actor_cnt
        FROM cast_info ci
        GROUP BY ci.movie_id
    ),
    character_counts AS (
        SELECT ci.movie_id AS movie_id,
               COUNT(DISTINCT ci.person_role_id) AS character_cnt
        FROM cast_info ci
        GROUP BY ci.movie_id
    ),
    company_counts AS (
        SELECT mc.movie_id AS movie_id,
               COUNT(DISTINCT mc.company_id) AS company_cnt
        FROM movie_companies mc
        GROUP BY mc.movie_id
    ),
    keyword_counts AS (
        SELECT mk.movie_id AS movie_id,
               COUNT(DISTINCT kw.keyword) AS keyword_cnt
        FROM movie_keyword mk
        JOIN keyword kw ON mk.keyword_id = kw.id
        GROUP BY mk.movie_id
    )
SELECT
    t.title,
    t.production_year,
    kt.kind,
    ac.actor_cnt,
    cc.character_cnt,
    comp.company_cnt,
    kc.keyword_cnt
FROM title t
JOIN kind_type kt
  ON t.kind_id = kt.id
LEFT JOIN actor_counts ac
  ON ac.movie_id = t.id
LEFT JOIN character_counts cc
  ON cc.movie_id = t.id
LEFT JOIN company_counts comp
  ON comp.movie_id = t.id
LEFT JOIN keyword_counts kc
  ON kc.movie_id = t.id
ORDER BY ac.actor_cnt DESC NULLS LAST
LIMIT 10

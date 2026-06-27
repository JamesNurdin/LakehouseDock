WITH cast_per_movie AS (
    SELECT movie_id,
           COUNT(DISTINCT person_id) AS cast_cnt
    FROM cast_info
    GROUP BY movie_id
),
keyword_per_movie AS (
    SELECT movie_id,
           COUNT(DISTINCT keyword_id) AS keyword_cnt
    FROM movie_keyword
    GROUP BY movie_id
),
info_per_movie AS (
    SELECT movie_id,
           COUNT(DISTINCT info_type_id) AS info_cnt
    FROM movie_info_idx
    GROUP BY movie_id
),
movie_company_type AS (
    SELECT DISTINCT mc.movie_id,
           ct.kind AS company_type
    FROM movie_companies mc
    JOIN company_type ct ON mc.company_type_id = ct.id
),
movie_year_company AS (
    SELECT t.production_year,
           mct.company_type,
           t.id AS movie_id,
           cp.cast_cnt,
           kp.keyword_cnt,
           ip.info_cnt
    FROM title t
    LEFT JOIN cast_per_movie cp ON cp.movie_id = t.id
    LEFT JOIN keyword_per_movie kp ON kp.movie_id = t.id
    LEFT JOIN info_per_movie ip ON ip.movie_id = t.id
    LEFT JOIN movie_company_type mct ON mct.movie_id = t.id
    WHERE t.production_year IS NOT NULL
      AND t.production_year >= 2000
)
SELECT production_year,
       company_type,
       COUNT(DISTINCT movie_id)               AS movie_count,
       AVG(cast_cnt)                          AS avg_cast_per_movie,
       AVG(keyword_cnt)                       AS avg_keywords_per_movie,
       AVG(info_cnt)                          AS avg_info_entries_per_movie
FROM movie_year_company
GROUP BY production_year, company_type
ORDER BY production_year DESC, movie_count DESC
LIMIT 100

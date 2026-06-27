WITH kw_counts AS (
    SELECT t.id AS movie_id,
           COUNT(DISTINCT mk.keyword_id) AS keyword_cnt
    FROM title t
    LEFT JOIN movie_keyword mk ON mk.movie_id = t.id
    GROUP BY t.id
),
cast_counts AS (
    SELECT t.id AS movie_id,
           COUNT(DISTINCT ci.person_id) AS cast_cnt,
           COUNT(DISTINCT CASE WHEN n.gender = 'M' THEN ci.person_id END) AS male_cast_cnt,
           COUNT(DISTINCT CASE WHEN n.gender = 'F' THEN ci.person_id END) AS female_cast_cnt
    FROM title t
    LEFT JOIN cast_info ci ON ci.movie_id = t.id
    LEFT JOIN name n ON ci.person_id = n.id
    GROUP BY t.id
),
company_counts AS (
    SELECT t.id AS movie_id,
           COUNT(DISTINCT mc.company_id) AS company_cnt
    FROM title t
    LEFT JOIN movie_companies mc ON mc.movie_id = t.id
    GROUP BY t.id
)
SELECT t.title,
       t.production_year,
       kt.kind,
       COALESCE(kw.keyword_cnt, 0) AS keyword_cnt,
       COALESCE(cc.cast_cnt, 0) AS cast_cnt,
       COALESCE(cc.male_cast_cnt, 0) AS male_cast_cnt,
       COALESCE(cc.female_cast_cnt, 0) AS female_cast_cnt,
       COALESCE(comp.company_cnt, 0) AS company_cnt
FROM title t
JOIN kind_type kt ON t.kind_id = kt.id
LEFT JOIN kw_counts kw ON kw.movie_id = t.id
LEFT JOIN cast_counts cc ON cc.movie_id = t.id
LEFT JOIN company_counts comp ON comp.movie_id = t.id
ORDER BY COALESCE(kw.keyword_cnt, 0) DESC
LIMIT 10

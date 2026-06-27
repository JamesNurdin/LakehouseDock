WITH movies AS (
    SELECT t.id AS movie_id,
           t.title,
           t.production_year,
           kt.kind AS kind_name
    FROM title t
    JOIN kind_type kt ON t.kind_id = kt.id
    WHERE t.production_year IS NOT NULL
),
cast_counts AS (
    SELECT ci.movie_id,
           COUNT(DISTINCT ci.person_id) AS cast_cnt,
           COUNT(DISTINCT ci.person_role_id) AS character_cnt
    FROM cast_info ci
    GROUP BY ci.movie_id
),
prod_company_counts AS (
    SELECT mc.movie_id,
           COUNT(DISTINCT cn.id) AS prod_company_cnt
    FROM movie_companies mc
    JOIN company_type ct ON mc.company_type_id = ct.id
    JOIN company_name cn ON mc.company_id = cn.id
    WHERE ct.kind = 'production'
    GROUP BY mc.movie_id
),
keyword_counts AS (
    SELECT mk.movie_id,
           COUNT(DISTINCT k.id) AS keyword_cnt
    FROM movie_keyword mk
    JOIN keyword k ON mk.keyword_id = k.id
    GROUP BY mk.movie_id
),
budget_info AS (
    SELECT mi.movie_id,
           TRY_CAST(mi.info AS double) AS budget
    FROM movie_info mi
    JOIN info_type it ON mi.info_type_id = it.id
    WHERE it.info = 'budget'
)
SELECT
    m.production_year,
    m.kind_name,
    COUNT(*) AS movie_cnt,
    SUM(COALESCE(cc.cast_cnt, 0)) AS total_cast,
    SUM(COALESCE(cc.character_cnt, 0)) AS total_characters,
    SUM(COALESCE(pc.prod_company_cnt, 0)) AS total_prod_companies,
    SUM(COALESCE(kc.keyword_cnt, 0)) AS total_keywords,
    AVG(COALESCE(kc.keyword_cnt, 0)) AS avg_keywords_per_movie,
    AVG(bi.budget) AS avg_budget
FROM movies m
LEFT JOIN cast_counts cc ON m.movie_id = cc.movie_id
LEFT JOIN prod_company_counts pc ON m.movie_id = pc.movie_id
LEFT JOIN keyword_counts kc ON m.movie_id = kc.movie_id
LEFT JOIN budget_info bi ON m.movie_id = bi.movie_id
GROUP BY m.production_year, m.kind_name
ORDER BY m.production_year DESC, m.kind_name

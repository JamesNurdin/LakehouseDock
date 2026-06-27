WITH cast_agg AS (
  SELECT ci.movie_id,
         COUNT(DISTINCT ci.person_id) AS distinct_cast,
         COUNT(DISTINCT cn.id) AS distinct_characters
  FROM cast_info ci
  LEFT JOIN char_name cn ON ci.person_role_id = cn.id
  GROUP BY ci.movie_id
),
company_agg AS (
  SELECT mc.movie_id,
         COUNT(DISTINCT cn.id) AS distinct_companies,
         COUNT(DISTINCT ct.kind) AS distinct_company_types
  FROM movie_companies mc
  JOIN company_name cn ON mc.company_id = cn.id
  JOIN company_type ct ON mc.company_type_id = ct.id
  GROUP BY mc.movie_id
),
keyword_agg AS (
  SELECT mk.movie_id,
         COUNT(DISTINCT k.keyword) AS distinct_keywords
  FROM movie_keyword mk
  JOIN keyword k ON mk.keyword_id = k.id
  GROUP BY mk.movie_id
),
aka_agg AS (
  SELECT ci.movie_id,
         COUNT(DISTINCT ak.id) AS distinct_aka_names
  FROM cast_info ci
  JOIN name n ON ci.person_id = n.id
  JOIN aka_name ak ON ak.person_id = n.id
  GROUP BY ci.movie_id
)
SELECT t.title,
       t.production_year,
       kt.kind AS kind,
       COALESCE(ca.distinct_cast, 0) AS cast_count,
       COALESCE(ca.distinct_characters, 0) AS character_count,
       COALESCE(coa.distinct_companies, 0) AS company_count,
       COALESCE(coa.distinct_company_types, 0) AS company_type_count,
       COALESCE(ka.distinct_keywords, 0) AS keyword_count,
       COALESCE(aa.distinct_aka_names, 0) AS aka_name_count
FROM title t
JOIN kind_type kt ON t.kind_id = kt.id
LEFT JOIN cast_agg ca   ON t.id = ca.movie_id
LEFT JOIN company_agg coa ON t.id = coa.movie_id
LEFT JOIN keyword_agg ka   ON t.id = ka.movie_id
LEFT JOIN aka_agg aa       ON t.id = aa.movie_id
WHERE t.production_year >= 2000
ORDER BY cast_count DESC
LIMIT 10

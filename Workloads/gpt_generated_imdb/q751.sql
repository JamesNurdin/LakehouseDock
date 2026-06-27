WITH movie_stats AS (
  SELECT
    t.id AS movie_id,
    t.title AS title,
    k.kind AS kind_name,
    t.production_year AS production_year,
    COUNT(DISTINCT ci.person_id) AS total_cast,
    COUNT(DISTINCT CASE WHEN n.gender = 'M' THEN ci.person_id END) AS male_cast,
    COUNT(DISTINCT CASE WHEN n.gender = 'F' THEN ci.person_id END) AS female_cast,
    COUNT(DISTINCT mc.company_id) AS total_companies,
    COUNT(DISTINCT CASE WHEN ct.kind = 'production' THEN mc.company_id END) AS production_companies,
    COUNT(DISTINCT CASE WHEN ct.kind = 'distribution' THEN mc.company_id END) AS distribution_companies,
    COUNT(DISTINCT cn.country_code) AS distinct_company_countries,
    COUNT(DISTINCT mk.keyword_id) AS total_keywords,
    MAX(CASE WHEN it.info = 'rating' THEN try_cast(mi.info AS double) END) AS rating,
    MAX(CASE WHEN it.info = 'budget' THEN try_cast(mi.info AS double) END) AS budget,
    COUNT(DISTINCT ch.id) AS distinct_characters
  FROM title t
  LEFT JOIN kind_type k ON t.kind_id = k.id
  LEFT JOIN cast_info ci ON ci.movie_id = t.id
  LEFT JOIN name n ON ci.person_id = n.id
  LEFT JOIN char_name ch ON ci.person_role_id = ch.id
  LEFT JOIN movie_companies mc ON mc.movie_id = t.id
  LEFT JOIN company_type ct ON mc.company_type_id = ct.id
  LEFT JOIN company_name cn ON mc.company_id = cn.id
  LEFT JOIN movie_info mi ON mi.movie_id = t.id
  LEFT JOIN info_type it ON mi.info_type_id = it.id
  LEFT JOIN movie_keyword mk ON mk.movie_id = t.id
  WHERE t.production_year >= 2010
  GROUP BY t.id, t.title, k.kind, t.production_year
)
SELECT
  movie_id,
  title,
  kind_name,
  production_year,
  total_cast,
  male_cast,
  female_cast,
  total_companies,
  production_companies,
  distribution_companies,
  distinct_company_countries,
  total_keywords,
  rating,
  budget,
  distinct_characters
FROM movie_stats
ORDER BY rating DESC NULLS LAST
LIMIT 100

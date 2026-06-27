SELECT
    t.id AS movie_id,
    t.title,
    kt.kind AS kind,
    COUNT(DISTINCT ci.person_id) AS cast_count,
    COUNT(DISTINCT ci.role_id) AS distinct_role_count,
    COUNT(DISTINCT mc.company_id) AS company_count,
    COUNT(DISTINCT CASE WHEN ct.kind = 'production' THEN mc.company_id END) AS production_company_count,
    COUNT(DISTINCT mk.keyword_id) AS keyword_count,
    SUM(CASE WHEN it.info = 'budget' THEN CAST(mi.info AS double) ELSE 0 END) AS total_budget,
    AVG(CASE WHEN it.info = 'rating' THEN CAST(mi.info AS double) END) AS avg_rating
FROM title t
JOIN kind_type kt ON t.kind_id = kt.id
LEFT JOIN cast_info ci ON ci.movie_id = t.id
LEFT JOIN name n ON ci.person_id = n.id
LEFT JOIN movie_companies mc ON mc.movie_id = t.id
LEFT JOIN company_type ct ON mc.company_type_id = ct.id
LEFT JOIN movie_info mi ON mi.movie_id = t.id
LEFT JOIN info_type it ON mi.info_type_id = it.id
LEFT JOIN movie_keyword mk ON mk.movie_id = t.id
LEFT JOIN keyword kw ON mk.keyword_id = kw.id
WHERE t.production_year >= 2000
GROUP BY t.id, t.title, kt.kind
ORDER BY cast_count DESC
LIMIT 100

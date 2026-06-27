SELECT
    t.production_year,
    kt.kind AS kind_name,
    COUNT(DISTINCT t.id) AS movie_count,
    SUM(CASE WHEN ci.role_id = 1 THEN 1 ELSE 0 END) AS lead_actor_count,
    COUNT(DISTINCT ci.person_id) AS distinct_cast_members,
    COUNT(DISTINCT mc.company_id) AS distinct_companies,
    COUNT(DISTINCT mc.company_id) FILTER (WHERE ct.kind = 'production') AS production_company_count,
    COUNT(DISTINCT mk.keyword_id) AS distinct_keywords,
    AVG(mii.note) FILTER (WHERE mii.info_type_id = 1) AS avg_note_type1
FROM title AS t
JOIN kind_type AS kt
    ON t.kind_id = kt.id
LEFT JOIN cast_info AS ci
    ON ci.movie_id = t.id
LEFT JOIN movie_companies AS mc
    ON mc.movie_id = t.id
LEFT JOIN company_type AS ct
    ON mc.company_type_id = ct.id
LEFT JOIN movie_info_idx AS mii
    ON mii.movie_id = t.id
LEFT JOIN movie_keyword AS mk
    ON mk.movie_id = t.id
WHERE t.production_year IS NOT NULL
GROUP BY t.production_year, kt.kind
ORDER BY t.production_year DESC, movie_count DESC
LIMIT 100

WITH tag_counts AS (
    SELECT
        person_id,
        COUNT(DISTINCT tag_id) AS tag_count
    FROM person_has_interest_tag
    GROUP BY person_id
)
SELECT
    o.id AS company_id,
    o.name AS company_name,
    o.type AS company_type,
    COUNT(DISTINCT f.id) AS forum_count,
    AVG(tc.tag_count) AS avg_tags_per_moderator,
    COUNT(DISTINCT p.location_city_id) AS distinct_residence_cities
FROM person_work_at_company pwc
JOIN person p ON pwc.person_id = p.id
JOIN forum f ON f.moderator_person_id = p.id
JOIN organisation o ON pwc.company_id = o.id
LEFT JOIN tag_counts tc ON tc.person_id = p.id
WHERE pwc.work_from >= 2005
GROUP BY o.id, o.name, o.type
ORDER BY forum_count DESC
LIMIT 10

WITH person_org AS (
    SELECT pwac.person_id,
           pwac.company_id AS org_id
    FROM person_work_at_company pwac
    UNION
    SELECT psau.person_id,
           psau.university_id AS org_id
    FROM person_study_at_university psau
)
SELECT
    o.id,
    o.name,
    o.type,
    COUNT(DISTINCT po.id) AS post_count,
    COUNT(DISTINCT p.id) AS distinct_creator_count,
    COUNT(c.id) AS comment_count,
    AVG(c.length) AS avg_comment_length
FROM person_org po_org
JOIN organisation o
    ON o.id = po_org.org_id
JOIN person p
    ON p.id = po_org.person_id
JOIN post po
    ON po.creator_person_id = p.id
LEFT JOIN comment c
    ON c.parent_post_id = po.id
GROUP BY
    o.id,
    o.name,
    o.type
ORDER BY post_count DESC
LIMIT 10

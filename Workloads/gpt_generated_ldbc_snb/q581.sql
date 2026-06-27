WITH comment_agg AS (
    SELECT
        tc.id AS tag_class_id,
        tc.name AS tag_class_name,
        pwac.company_id AS company_id,
        COUNT(DISTINCT c.id) AS comment_count,
        AVG(c.length) AS avg_comment_length,
        COUNT(DISTINCT c.creator_person_id) AS distinct_comment_creators
    FROM comment c
    JOIN comment_has_tag_tag chtag ON c.id = chtag.comment_id
    JOIN tag t ON chtag.tag_id = t.id
    JOIN tag_class tc ON t.type_tag_class_id = tc.id
    JOIN person p ON c.creator_person_id = p.id
    LEFT JOIN person_work_at_company pwac ON p.id = pwac.person_id
    GROUP BY tc.id, tc.name, pwac.company_id
    HAVING COUNT(DISTINCT c.id) > 5
),
post_agg AS (
    SELECT
        tc.id AS tag_class_id,
        tc.name AS tag_class_name,
        pwac.company_id AS company_id,
        COUNT(DISTINCT po.id) AS post_count,
        AVG(po.length) AS avg_post_length,
        COUNT(DISTINCT po.creator_person_id) AS distinct_post_creators
    FROM post po
    JOIN post_has_tag_tag phtag ON po.id = phtag.post_id
    JOIN tag t ON phtag.tag_id = t.id
    JOIN tag_class tc ON t.type_tag_class_id = tc.id
    JOIN person p2 ON po.creator_person_id = p2.id
    LEFT JOIN person_work_at_company pwac ON p2.id = pwac.person_id
    GROUP BY tc.id, tc.name, pwac.company_id
    HAVING COUNT(DISTINCT po.id) > 5
)
SELECT
    COALESCE(ca.tag_class_id, pa.tag_class_id) AS tag_class_id,
    COALESCE(ca.tag_class_name, pa.tag_class_name) AS tag_class_name,
    COALESCE(ca.company_id, pa.company_id) AS company_id,
    ca.comment_count,
    ca.avg_comment_length,
    ca.distinct_comment_creators,
    pa.post_count,
    pa.avg_post_length,
    pa.distinct_post_creators,
    COALESCE(ca.comment_count, 0) + COALESCE(pa.post_count, 0) AS total_content_count
FROM comment_agg ca
FULL OUTER JOIN post_agg pa
    ON ca.tag_class_id = pa.tag_class_id
   AND ca.company_id = pa.company_id
ORDER BY total_content_count DESC

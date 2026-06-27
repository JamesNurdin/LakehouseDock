WITH post_counts AS (
    SELECT tag_id,
           COUNT(DISTINCT post_id) AS post_count
    FROM post_has_tag_tag
    GROUP BY tag_id
),
comment_counts AS (
    SELECT tag_id,
           COUNT(DISTINCT comment_id) AS comment_count
    FROM comment_has_tag_tag
    GROUP BY tag_id
),
interest_counts AS (
    SELECT p_i.tag_id,
           COUNT(DISTINCT p_i.person_id) AS interest_count
    FROM person_has_interest_tag p_i
    JOIN person p ON p_i.person_id = p.id
    WHERE p.gender = 'female'
    GROUP BY p_i.tag_id
)
SELECT
    t.id                                      AS tag_id,
    t.name                                    AS tag_name,
    tc.name                                   AS tag_class_name,
    ptc.name                                  AS parent_tag_class_name,
    COALESCE(pc.post_count, 0)                AS post_count,
    COALESCE(cc.comment_count, 0)             AS comment_count,
    COALESCE(ic.interest_count, 0)            AS interest_person_count,
    COALESCE(pc.post_count, 0) + COALESCE(cc.comment_count, 0) + COALESCE(ic.interest_count, 0) AS total_usage
FROM tag t
LEFT JOIN post_counts pc   ON t.id = pc.tag_id
LEFT JOIN comment_counts cc ON t.id = cc.tag_id
LEFT JOIN interest_counts ic ON t.id = ic.tag_id
JOIN tag_class tc ON t.type_tag_class_id = tc.id
LEFT JOIN tag_class ptc ON tc.subclass_of_tag_class_id = ptc.id
WHERE COALESCE(pc.post_count, 0) + COALESCE(cc.comment_count, 0) + COALESCE(ic.interest_count, 0) > 0
ORDER BY total_usage DESC
LIMIT 10

WITH authored_comments AS (
    SELECT
        p.id AS person_id,
        COUNT(c.id) AS authored_comment_count,
        AVG(c.length) AS avg_authored_comment_length
    FROM person p
    JOIN comment c ON c.creator_person_id = p.id
    GROUP BY p.id
),
liked_comments AS (
    SELECT
        p.id AS person_id,
        COUNT(plc.comment_id) AS liked_comment_count,
        COUNT(DISTINCT plc.comment_id) AS distinct_liked_comments
    FROM person p
    JOIN person_likes_comment plc ON plc.person_id = p.id
    GROUP BY p.id
),
tags_used AS (
    SELECT
        p.id AS person_id,
        COUNT(DISTINCT t.id) AS distinct_tags_used,
        COUNT(DISTINCT tc.id) AS distinct_tag_classes_used
    FROM person p
    JOIN comment c ON c.creator_person_id = p.id
    JOIN comment_has_tag_tag cht ON cht.comment_id = c.id
    JOIN tag t ON t.id = cht.tag_id
    JOIN tag_class tc ON tc.id = t.type_tag_class_id
    GROUP BY p.id
)
SELECT
    p.id,
    p.first_name,
    p.last_name,
    COALESCE(ac.authored_comment_count, 0) AS authored_comment_count,
    COALESCE(ac.avg_authored_comment_length, 0) AS avg_authored_comment_length,
    COALESCE(lc.liked_comment_count, 0) AS liked_comment_count,
    COALESCE(tu.distinct_tags_used, 0) AS distinct_tags_used,
    COALESCE(tu.distinct_tag_classes_used, 0) AS distinct_tag_classes_used
FROM person p
LEFT JOIN authored_comments ac ON ac.person_id = p.id
LEFT JOIN liked_comments lc ON lc.person_id = p.id
LEFT JOIN tags_used tu ON tu.person_id = p.id
ORDER BY authored_comment_count DESC
LIMIT 100

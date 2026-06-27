WITH post_agg AS (
    SELECT
        tc.id AS tag_class_id,
        tc.name AS tag_class_name,
        COUNT(DISTINCT p.id) AS post_count,
        SUM(p.length) / NULLIF(COUNT(DISTINCT p.id), 0) AS avg_post_length,
        COUNT(DISTINCT p.creator_person_id) AS distinct_post_authors
    FROM
        tag_class tc
        JOIN tag t ON t.type_tag_class_id = tc.id
        JOIN post_has_tag_tag pht ON pht.tag_id = t.id
        JOIN post p ON p.id = pht.post_id
    GROUP BY
        tc.id,
        tc.name
),
comment_agg AS (
    SELECT
        tc.id AS tag_class_id,
        tc.name AS tag_class_name,
        COUNT(DISTINCT c.id) AS comment_count,
        SUM(c.length) / NULLIF(COUNT(DISTINCT c.id), 0) AS avg_comment_length,
        COUNT(DISTINCT c.creator_person_id) AS distinct_comment_authors
    FROM
        tag_class tc
        JOIN tag t ON t.type_tag_class_id = tc.id
        JOIN comment_has_tag_tag cht ON cht.tag_id = t.id
        JOIN comment c ON c.id = cht.comment_id
    GROUP BY
        tc.id,
        tc.name
)
SELECT
    COALESCE(p.tag_class_name, cm.tag_class_name) AS tag_class_name,
    COALESCE(p.post_count, 0) AS post_count,
    COALESCE(cm.comment_count, 0) AS comment_count,
    p.avg_post_length,
    cm.avg_comment_length,
    COALESCE(p.distinct_post_authors, 0) AS distinct_post_authors,
    COALESCE(cm.distinct_comment_authors, 0) AS distinct_comment_authors
FROM
    post_agg p
    FULL OUTER JOIN comment_agg cm ON p.tag_class_id = cm.tag_class_id
ORDER BY
    post_count DESC,
    comment_count DESC
LIMIT 20

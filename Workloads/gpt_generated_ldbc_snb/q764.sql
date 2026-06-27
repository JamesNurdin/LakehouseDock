WITH comment_stats AS (
    SELECT
        tc.id AS tag_class_id,
        COUNT(DISTINCT c.id) AS total_comments,
        AVG(c.length) AS avg_comment_length,
        COUNT(DISTINCT c.creator_person_id) AS distinct_creators,
        SUM(CASE WHEN c.parent_comment_id IS NOT NULL THEN 1 ELSE 0 END) AS reply_comments,
        SUM(CASE WHEN c.parent_comment_id IS NOT NULL AND c_parent.creator_person_id <> c.creator_person_id THEN 1 ELSE 0 END) AS replies_to_different_creator
    FROM comment_has_tag_tag cht
    JOIN comment c ON cht.comment_id = c.id
    JOIN tag t ON cht.tag_id = t.id
    JOIN tag_class tc ON t.type_tag_class_id = tc.id
    LEFT JOIN comment c_parent ON c.parent_comment_id = c_parent.id
    GROUP BY tc.id
),
forum_stats AS (
    SELECT
        tc.id AS tag_class_id,
        COUNT(DISTINCT fht.forum_id) AS total_forums_tagged,
        COUNT(*) AS total_forum_tags
    FROM forum_has_tag_tag fht
    JOIN tag t ON fht.tag_id = t.id
    JOIN tag_class tc ON t.type_tag_class_id = tc.id
    GROUP BY tc.id
)
SELECT
    tc.id,
    tc.name,
    COALESCE(cs.total_comments, 0) AS total_comments,
    COALESCE(cs.avg_comment_length, 0) AS avg_comment_length,
    COALESCE(cs.distinct_creators, 0) AS distinct_creators,
    COALESCE(cs.reply_comments, 0) AS reply_comments,
    COALESCE(cs.replies_to_different_creator, 0) AS replies_to_different_creator,
    COALESCE(fs.total_forums_tagged, 0) AS total_forums_tagged,
    COALESCE(fs.total_forum_tags, 0) AS total_forum_tags,
    ROW_NUMBER() OVER (ORDER BY COALESCE(cs.total_comments, 0) DESC) AS rank
FROM tag_class tc
LEFT JOIN comment_stats cs ON tc.id = cs.tag_class_id
LEFT JOIN forum_stats fs ON tc.id = fs.tag_class_id
ORDER BY total_comments DESC
LIMIT 100

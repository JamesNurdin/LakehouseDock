-- Analytical query: tag usage across comments, forums, posts, person interests, and reply statistics
WITH comment_tag_stats AS (
    SELECT
        t.id AS tag_id,
        COUNT(DISTINCT c.id) AS comment_count,
        SUM(c.length) AS total_comment_length,
        COUNT(DISTINCT c.creator_person_id) AS distinct_commenters
    FROM tag t
    JOIN comment_has_tag_tag ct ON ct.tag_id = t.id
    JOIN comment c ON c.id = ct.comment_id
    GROUP BY t.id
),
forum_tag_stats AS (
    SELECT
        t.id AS tag_id,
        COUNT(DISTINCT f.forum_id) AS forum_count
    FROM tag t
    JOIN forum_has_tag_tag f ON f.tag_id = t.id
    GROUP BY t.id
),
post_tag_stats AS (
    SELECT
        t.id AS tag_id,
        COUNT(DISTINCT p.post_id) AS post_count
    FROM tag t
    JOIN post_has_tag_tag p ON p.tag_id = t.id
    GROUP BY t.id
),
person_interest_stats AS (
    SELECT
        t.id AS tag_id,
        COUNT(DISTINCT pi.person_id) AS person_interest_count
    FROM tag t
    JOIN person_has_interest_tag pi ON pi.tag_id = t.id
    GROUP BY t.id
),
reply_stats AS (
    SELECT
        tag_id,
        SUM(reply_per_parent) AS reply_count,
        AVG(reply_per_parent) AS avg_replies_per_parent
    FROM (
        SELECT
            parent.id AS parent_comment_id,
            COUNT(child.id) AS reply_per_parent,
            t.id AS tag_id
        FROM tag t
        JOIN comment_has_tag_tag ct_parent ON ct_parent.tag_id = t.id
        JOIN comment parent ON parent.id = ct_parent.comment_id
        LEFT JOIN comment child ON child.parent_comment_id = parent.id
        GROUP BY parent.id, t.id
    ) parent_stats
    GROUP BY tag_id
)
SELECT
    t.id,
    t.name,
    COALESCE(cts.comment_count, 0) AS comment_count,
    COALESCE(cts.total_comment_length, 0) AS total_comment_length,
    COALESCE(cts.distinct_commenters, 0) AS distinct_commenters,
    COALESCE(fts.forum_count, 0) AS forum_count,
    COALESCE(pts.post_count, 0) AS post_count,
    COALESCE(pis.person_interest_count, 0) AS person_interest_count,
    COALESCE(rs.reply_count, 0) AS reply_count,
    COALESCE(rs.avg_replies_per_parent, 0) AS avg_replies_per_parent
FROM tag t
LEFT JOIN comment_tag_stats cts ON cts.tag_id = t.id
LEFT JOIN forum_tag_stats fts ON fts.tag_id = t.id
LEFT JOIN post_tag_stats pts ON pts.tag_id = t.id
LEFT JOIN person_interest_stats pis ON pis.tag_id = t.id
LEFT JOIN reply_stats rs ON rs.tag_id = t.id
ORDER BY comment_count DESC
LIMIT 100

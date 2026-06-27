WITH comment_stats AS (
    SELECT
        f.id AS forum_id,
        COUNT(DISTINCT c.id) AS total_comments,
        AVG(c.length) AS avg_comment_length,
        COUNT(DISTINCT c.creator_person_id) AS distinct_commenters,
        COUNT(DISTINCT ct.tag_id) AS distinct_comment_tags
    FROM comment c
    JOIN post p ON c.parent_post_id = p.id
    JOIN forum f ON p.container_forum_id = f.id
    LEFT JOIN comment_has_tag_tag ct ON ct.comment_id = c.id
    WHERE c.parent_post_id IS NOT NULL
    GROUP BY f.id
),
comment_likes AS (
    SELECT
        f.id AS forum_id,
        COUNT(plc.person_id) AS total_comment_likes
    FROM person_likes_comment plc
    JOIN comment c ON plc.comment_id = c.id
    JOIN post p ON c.parent_post_id = p.id
    JOIN forum f ON p.container_forum_id = f.id
    GROUP BY f.id
),
forum_members AS (
    SELECT
        f.id AS forum_id,
        COUNT(DISTINCT fm.person_id) AS member_count
    FROM forum_has_member_person fm
    JOIN forum f ON fm.forum_id = f.id
    GROUP BY f.id
)
SELECT
    f.id AS forum_id,
    f.title,
    cs.total_comments,
    cs.avg_comment_length,
    cs.distinct_commenters,
    cs.distinct_comment_tags,
    cl.total_comment_likes,
    fm.member_count
FROM forum f
LEFT JOIN comment_stats cs ON f.id = cs.forum_id
LEFT JOIN comment_likes cl ON f.id = cl.forum_id
LEFT JOIN forum_members fm ON f.id = fm.forum_id
ORDER BY cs.total_comments DESC NULLS LAST
LIMIT 10

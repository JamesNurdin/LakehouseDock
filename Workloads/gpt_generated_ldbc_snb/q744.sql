WITH post_stats AS (
    SELECT
        post.container_forum_id AS forum_id,
        COUNT(*) AS post_count,
        AVG(post.length) AS avg_post_length
    FROM post
    GROUP BY post.container_forum_id
),
comment_stats AS (
    SELECT
        post.container_forum_id AS forum_id,
        COUNT(*) AS comment_count,
        AVG(comment.length) AS avg_comment_length
    FROM comment
    JOIN post ON comment.parent_post_id = post.id
    GROUP BY post.container_forum_id
),
post_like_stats AS (
    SELECT
        post.container_forum_id AS forum_id,
        COUNT(*) AS post_like_count
    FROM person_likes_post
    JOIN post ON person_likes_post.post_id = post.id
    GROUP BY post.container_forum_id
),
comment_like_stats AS (
    SELECT
        post.container_forum_id AS forum_id,
        COUNT(*) AS comment_like_count
    FROM person_likes_comment
    JOIN comment ON person_likes_comment.comment_id = comment.id
    JOIN post ON comment.parent_post_id = post.id
    GROUP BY post.container_forum_id
),
member_stats AS (
    SELECT
        forum_has_member_person.forum_id,
        COUNT(DISTINCT forum_has_member_person.person_id) AS member_count
    FROM forum_has_member_person
    GROUP BY forum_has_member_person.forum_id
),
contributor_stats AS (
    SELECT
        sub.forum_id,
        COUNT(DISTINCT sub.contributor_id) AS contributor_count
    FROM (
        SELECT
            post.container_forum_id AS forum_id,
            post.creator_person_id AS contributor_id
        FROM post
        UNION ALL
        SELECT
            post.container_forum_id AS forum_id,
            comment.creator_person_id AS contributor_id
        FROM comment
        JOIN post ON comment.parent_post_id = post.id
    ) sub
    GROUP BY sub.forum_id
)
SELECT
    f.id AS forum_id,
    f.title AS forum_title,
    f.creation_date AS forum_creation_date,
    p_mod.first_name AS moderator_first_name,
    p_mod.last_name AS moderator_last_name,
    COALESCE(ps.post_count, 0) AS post_count,
    COALESCE(ps.avg_post_length, 0) AS avg_post_length,
    COALESCE(cs.comment_count, 0) AS comment_count,
    COALESCE(cs.avg_comment_length, 0) AS avg_comment_length,
    COALESCE(pls.post_like_count, 0) AS post_like_count,
    COALESCE(cls.comment_like_count, 0) AS comment_like_count,
    COALESCE(ms.member_count, 0) AS member_count,
    COALESCE(cs2.contributor_count, 0) AS contributor_count
FROM forum f
LEFT JOIN person p_mod ON f.moderator_person_id = p_mod.id
LEFT JOIN post_stats ps ON f.id = ps.forum_id
LEFT JOIN comment_stats cs ON f.id = cs.forum_id
LEFT JOIN post_like_stats pls ON f.id = pls.forum_id
LEFT JOIN comment_like_stats cls ON f.id = cls.forum_id
LEFT JOIN member_stats ms ON f.id = ms.forum_id
LEFT JOIN contributor_stats cs2 ON f.id = cs2.forum_id
ORDER BY post_count DESC
LIMIT 100

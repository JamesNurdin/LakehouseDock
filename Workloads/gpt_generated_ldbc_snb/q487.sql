WITH
    -- Base forum information
    forum_base AS (
        SELECT
            f.id AS forum_id,
            f.title,
            f.moderator_person_id
        FROM forum f
    ),
    -- Moderator personal details
    moderator AS (
        SELECT
            p.id AS person_id,
            p.first_name AS moderator_first_name,
            p.last_name  AS moderator_last_name
        FROM person p
    ),
    -- Number of members per forum
    member_counts AS (
        SELECT
            fm.forum_id,
            COUNT(DISTINCT fm.person_id) AS member_count
        FROM forum_has_member_person fm
        GROUP BY fm.forum_id
    ),
    -- Number of posts per forum
    post_counts AS (
        SELECT
            p.container_forum_id AS forum_id,
            COUNT(DISTINCT p.id) AS post_count
        FROM post p
        GROUP BY p.container_forum_id
    ),
    -- Number of comments (directly attached to a post) per forum
    comment_counts AS (
        SELECT
            p.container_forum_id AS forum_id,
            COUNT(DISTINCT c.id) AS comment_count
        FROM comment c
        JOIN post p ON c.parent_post_id = p.id
        GROUP BY p.container_forum_id
    ),
    -- Number of likes on posts per forum
    post_like_counts AS (
        SELECT
            p.container_forum_id AS forum_id,
            COUNT(*) AS post_like_count
        FROM person_likes_post plp
        JOIN post p ON plp.post_id = p.id
        GROUP BY p.container_forum_id
    ),
    -- Number of likes on comments per forum
    comment_like_counts AS (
        SELECT
            p.container_forum_id AS forum_id,
            COUNT(*) AS comment_like_count
        FROM person_likes_comment plc
        JOIN comment c ON plc.comment_id = c.id
        JOIN post p ON c.parent_post_id = p.id
        GROUP BY p.container_forum_id
    ),
    -- All tag usages (from posts and comments) with their forum context
    tag_usage_raw AS (
        -- Tags coming from posts
        SELECT
            p.container_forum_id AS forum_id,
            pt.tag_id,
            t.name AS tag_name
        FROM post_has_tag_tag pt
        JOIN post p ON pt.post_id = p.id
        JOIN tag t ON pt.tag_id = t.id
        UNION ALL
        -- Tags coming from comments
        SELECT
            p.container_forum_id AS forum_id,
            ct.tag_id,
            t.name AS tag_name
        FROM comment_has_tag_tag ct
        JOIN comment c ON ct.comment_id = c.id
        JOIN post p ON c.parent_post_id = p.id
        JOIN tag t ON ct.tag_id = t.id
    ),
    -- Aggregate tag usage counts per forum
    tag_counts AS (
        SELECT
            forum_id,
            tag_id,
            tag_name,
            COUNT(*) AS tag_use_count
        FROM tag_usage_raw
        GROUP BY forum_id, tag_id, tag_name
    ),
    -- Top 3 tags per forum (by usage count)
    top_tags AS (
        SELECT
            forum_id,
            ARRAY_AGG(tag_name ORDER BY tag_use_count DESC) AS top_tags
        FROM (
            SELECT
                tc.forum_id,
                tc.tag_name,
                tc.tag_use_count,
                ROW_NUMBER() OVER (PARTITION BY tc.forum_id ORDER BY tc.tag_use_count DESC) AS rn
            FROM tag_counts tc
        ) ranked
        WHERE ranked.rn <= 3
        GROUP BY forum_id
    )
SELECT
    fb.forum_id,
    fb.title,
    m.moderator_first_name,
    m.moderator_last_name,
    COALESCE(mc.member_count, 0)          AS member_count,
    COALESCE(pc.post_count, 0)            AS post_count,
    COALESCE(cc.comment_count, 0)         AS comment_count,
    COALESCE(plc.post_like_count, 0)      AS post_like_count,
    COALESCE(clc.comment_like_count, 0)   AS comment_like_count,
    tt.top_tags
FROM forum_base fb
LEFT JOIN moderator m ON fb.moderator_person_id = m.person_id
LEFT JOIN member_counts mc ON fb.forum_id = mc.forum_id
LEFT JOIN post_counts pc ON fb.forum_id = pc.forum_id
LEFT JOIN comment_counts cc ON fb.forum_id = cc.forum_id
LEFT JOIN post_like_counts plc ON fb.forum_id = plc.forum_id
LEFT JOIN comment_like_counts clc ON fb.forum_id = clc.forum_id
LEFT JOIN top_tags tt ON fb.forum_id = tt.forum_id
ORDER BY fb.forum_id

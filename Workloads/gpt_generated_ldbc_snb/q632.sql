WITH
    forum_base AS (
        SELECT
            f.id AS forum_id,
            f.title AS forum_title,
            f.moderator_person_id
        FROM forum f
    ),
    post_stats AS (
        SELECT
            p.container_forum_id AS forum_id,
            COUNT(*) AS total_posts,
            AVG(p.length) AS avg_post_length
        FROM post p
        GROUP BY p.container_forum_id
    ),
    comment_stats AS (
        SELECT
            p.container_forum_id AS forum_id,
            COUNT(*) AS total_comments,
            AVG(c.length) AS avg_comment_length
        FROM comment c
        JOIN post p ON c.parent_post_id = p.id
        GROUP BY p.container_forum_id
    ),
    post_like_stats AS (
        SELECT
            p.container_forum_id AS forum_id,
            COUNT(DISTINCT plc.person_id) AS total_post_likes
        FROM person_likes_post plc
        JOIN post p ON plc.post_id = p.id
        GROUP BY p.container_forum_id
    ),
    comment_like_stats AS (
        SELECT
            p.container_forum_id AS forum_id,
            COUNT(DISTINCT plc.person_id) AS total_comment_likes
        FROM person_likes_comment plc
        JOIN comment c ON plc.comment_id = c.id
        JOIN post p ON c.parent_post_id = p.id
        GROUP BY p.container_forum_id
    ),
    member_stats AS (
        SELECT
            fm.forum_id AS forum_id,
            COUNT(DISTINCT fm.person_id) AS total_members
        FROM forum_has_member_person fm
        GROUP BY fm.forum_id
    ),
    top_tags AS (
        SELECT
            forum_id,
            array_agg(tag_id) AS top_3_tags
        FROM (
            SELECT
                p.container_forum_id AS forum_id,
                ct.tag_id,
                COUNT(*) AS tag_cnt,
                row_number() OVER (PARTITION BY p.container_forum_id ORDER BY COUNT(*) DESC) AS rn
            FROM comment_has_tag_tag ct
            JOIN comment c ON ct.comment_id = c.id
            JOIN post p ON c.parent_post_id = p.id
            GROUP BY p.container_forum_id, ct.tag_id
        ) t
        WHERE rn <= 3
        GROUP BY forum_id
    ),
    moderator_info AS (
        SELECT
            p.id AS moderator_id,
            p.first_name,
            p.last_name
        FROM person p
    )
SELECT
    fb.forum_id,
    fb.forum_title,
    CONCAT(mi.first_name, ' ', mi.last_name) AS moderator_name,
    COALESCE(ps.total_posts, 0) AS total_posts,
    COALESCE(cs.total_comments, 0) AS total_comments,
    ps.avg_post_length,
    cs.avg_comment_length,
    COALESCE(pls.total_post_likes, 0) AS total_post_likes,
    COALESCE(cls.total_comment_likes, 0) AS total_comment_likes,
    COALESCE(ms.total_members, 0) AS total_members,
    tt.top_3_tags
FROM forum_base fb
LEFT JOIN post_stats ps ON ps.forum_id = fb.forum_id
LEFT JOIN comment_stats cs ON cs.forum_id = fb.forum_id
LEFT JOIN post_like_stats pls ON pls.forum_id = fb.forum_id
LEFT JOIN comment_like_stats cls ON cls.forum_id = fb.forum_id
LEFT JOIN member_stats ms ON ms.forum_id = fb.forum_id
LEFT JOIN top_tags tt ON tt.forum_id = fb.forum_id
LEFT JOIN moderator_info mi ON mi.moderator_id = fb.moderator_person_id
ORDER BY total_posts DESC
LIMIT 10

WITH forum_base AS (
    SELECT f.id AS forum_id,
           f.title AS forum_title,
           mod.first_name AS moderator_first_name,
           mod.last_name AS moderator_last_name
    FROM forum f
    LEFT JOIN person mod ON f.moderator_person_id = mod.id
),
post_stats AS (
    SELECT p.container_forum_id AS forum_id,
           COUNT(*) AS num_posts,
           AVG(p.length) AS avg_post_length,
           COUNT(DISTINCT p.creator_person_id) AS num_post_creators
    FROM post p
    GROUP BY p.container_forum_id
),
comment_stats AS (
    SELECT p.container_forum_id AS forum_id,
           COUNT(*) AS num_comments,
           AVG(c.length) AS avg_comment_length,
           COUNT(DISTINCT c.creator_person_id) AS num_comment_creators
    FROM comment c
    JOIN post p ON c.parent_post_id = p.id
    GROUP BY p.container_forum_id
),
member_stats AS (
    SELECT fm.forum_id,
           COUNT(DISTINCT fm.person_id) AS num_members
    FROM forum_has_member_person fm
    GROUP BY fm.forum_id
),
post_likes AS (
    SELECT p.container_forum_id AS forum_id,
           SUM(likes_per_post) AS total_post_likes
    FROM (
        SELECT post_id, COUNT(*) AS likes_per_post
        FROM person_likes_post
        GROUP BY post_id
    ) pl
    JOIN post p ON pl.post_id = p.id
    GROUP BY p.container_forum_id
),
comment_likes AS (
    SELECT p.container_forum_id AS forum_id,
           SUM(likes_per_comment) AS total_comment_likes
    FROM (
        SELECT comment_id, COUNT(*) AS likes_per_comment
        FROM person_likes_comment
        GROUP BY comment_id
    ) cl
    JOIN comment c ON cl.comment_id = c.id
    JOIN post p ON c.parent_post_id = p.id
    GROUP BY p.container_forum_id
),
post_tag_stats AS (
    SELECT p.container_forum_id AS forum_id,
           COUNT(DISTINCT pt.tag_id) AS num_post_tags
    FROM post_has_tag_tag pt
    JOIN post p ON pt.post_id = p.id
    GROUP BY p.container_forum_id
),
comment_tag_stats AS (
    SELECT p.container_forum_id AS forum_id,
           COUNT(DISTINCT ct.tag_id) AS num_comment_tags
    FROM comment_has_tag_tag ct
    JOIN comment c ON ct.comment_id = c.id
    JOIN post p ON c.parent_post_id = p.id
    GROUP BY p.container_forum_id
)
SELECT fb.forum_id,
       fb.forum_title,
       fb.moderator_first_name,
       fb.moderator_last_name,
       COALESCE(ps.num_posts, 0) AS num_posts,
       COALESCE(cs.num_comments, 0) AS num_comments,
       ps.avg_post_length,
       cs.avg_comment_length,
       COALESCE(ms.num_members, 0) AS num_members,
       ps.num_post_creators,
       cs.num_comment_creators,
       COALESCE(pl.total_post_likes, 0) AS total_post_likes,
       COALESCE(cl.total_comment_likes, 0) AS total_comment_likes,
       COALESCE(pt.num_post_tags, 0) AS num_post_tags,
       COALESCE(ct.num_comment_tags, 0) AS num_comment_tags
FROM forum_base fb
LEFT JOIN post_stats ps ON fb.forum_id = ps.forum_id
LEFT JOIN comment_stats cs ON fb.forum_id = cs.forum_id
LEFT JOIN member_stats ms ON fb.forum_id = ms.forum_id
LEFT JOIN post_likes pl ON fb.forum_id = pl.forum_id
LEFT JOIN comment_likes cl ON fb.forum_id = cl.forum_id
LEFT JOIN post_tag_stats pt ON fb.forum_id = pt.forum_id
LEFT JOIN comment_tag_stats ct ON fb.forum_id = ct.forum_id
ORDER BY fb.forum_id

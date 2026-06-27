WITH forum_base AS (
    SELECT f.id AS forum_id,
           f.title AS forum_title,
           mod.first_name AS moderator_first_name,
           mod.last_name AS moderator_last_name
    FROM forum f
    LEFT JOIN person mod ON f.moderator_person_id = mod.id
),
post_agg AS (
    SELECT p.container_forum_id AS forum_id,
           COUNT(DISTINCT p.id) AS total_posts,
           COALESCE(SUM(p.length), 0) AS total_post_length,
           COALESCE(AVG(p.length), 0) AS avg_post_length
    FROM post p
    GROUP BY p.container_forum_id
),
comment_agg AS (
    SELECT p.container_forum_id AS forum_id,
           COUNT(DISTINCT c.id) AS total_comments
    FROM comment c
    JOIN post p ON c.parent_post_id = p.id
    GROUP BY p.container_forum_id
),
post_likes_agg AS (
    SELECT p.container_forum_id AS forum_id,
           COUNT(*) AS total_likes_on_posts
    FROM person_likes_post plp
    JOIN post p ON plp.post_id = p.id
    GROUP BY p.container_forum_id
),
comment_likes_agg AS (
    SELECT p.container_forum_id AS forum_id,
           COUNT(*) AS total_likes_on_comments
    FROM person_likes_comment plc
    JOIN comment c ON plc.comment_id = c.id
    JOIN post p ON c.parent_post_id = p.id
    GROUP BY p.container_forum_id
),
member_agg AS (
    SELECT forum_id,
           COUNT(DISTINCT person_id) AS distinct_members
    FROM forum_has_member_person
    GROUP BY forum_id
),
tag_agg AS (
    SELECT forum_id,
           COUNT(DISTINCT tag_id) AS distinct_tags
    FROM forum_has_tag_tag
    GROUP BY forum_id
)
SELECT
    fb.forum_id,
    fb.forum_title,
    fb.moderator_first_name,
    fb.moderator_last_name,
    COALESCE(pa.total_posts, 0) AS total_posts,
    COALESCE(pa.total_post_length, 0) AS total_post_length,
    COALESCE(pa.avg_post_length, 0) AS avg_post_length,
    COALESCE(ca.total_comments, 0) AS total_comments,
    COALESCE(pla.total_likes_on_posts, 0) AS total_likes_on_posts,
    COALESCE(cla.total_likes_on_comments, 0) AS total_likes_on_comments,
    COALESCE(ma.distinct_members, 0) AS distinct_members,
    COALESCE(ta.distinct_tags, 0) AS distinct_tags,
    (COALESCE(pa.total_posts, 0) + COALESCE(ca.total_comments, 0) + COALESCE(pla.total_likes_on_posts, 0) + COALESCE(cla.total_likes_on_comments, 0)) AS engagement_score
FROM forum_base fb
LEFT JOIN post_agg pa   ON fb.forum_id = pa.forum_id
LEFT JOIN comment_agg ca ON fb.forum_id = ca.forum_id
LEFT JOIN post_likes_agg pla ON fb.forum_id = pla.forum_id
LEFT JOIN comment_likes_agg cla ON fb.forum_id = cla.forum_id
LEFT JOIN member_agg ma ON fb.forum_id = ma.forum_id
LEFT JOIN tag_agg ta    ON fb.forum_id = ta.forum_id
ORDER BY engagement_score DESC
LIMIT 10

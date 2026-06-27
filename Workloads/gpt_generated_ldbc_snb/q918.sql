WITH
    -- Number of distinct members in each forum
    forum_members AS (
        SELECT forum_id,
               COUNT(DISTINCT person_id) AS member_count
        FROM forum_has_member_person
        GROUP BY forum_id
    ),
    -- Number of distinct tags explicitly attached to each forum
    forum_tags AS (
        SELECT forum_id,
               COUNT(DISTINCT tag_id) AS forum_tag_count
        FROM forum_has_tag_tag
        GROUP BY forum_id
    ),
    -- Basic post statistics per forum
    post_stats AS (
        SELECT p.container_forum_id AS forum_id,
               COUNT(*) AS post_count,
               AVG(p.length) AS avg_post_length
        FROM post p
        GROUP BY p.container_forum_id
    ),
    -- Distinct tags used on posts that belong to each forum
    post_tag_stats AS (
        SELECT p.container_forum_id AS forum_id,
               COUNT(DISTINCT pt.tag_id) AS post_tag_count
        FROM post p
        JOIN post_has_tag_tag pt ON p.id = pt.post_id
        GROUP BY p.container_forum_id
    ),
    -- Number of comments on posts belonging to each forum
    comment_stats AS (
        SELECT p.container_forum_id AS forum_id,
               COUNT(*) AS comment_count
        FROM comment c
        JOIN post p ON c.parent_post_id = p.id
        GROUP BY p.container_forum_id
    ),
    -- Likes received on posts per forum
    post_likes_stats AS (
        SELECT p.container_forum_id AS forum_id,
               COUNT(*) AS post_like_count
        FROM post p
        JOIN person_likes_post plp ON p.id = plp.post_id
        GROUP BY p.container_forum_id
    ),
    -- Likes received on comments (via the posts they belong to) per forum
    comment_likes_stats AS (
        SELECT p.container_forum_id AS forum_id,
               COUNT(*) AS comment_like_count
        FROM comment c
        JOIN post p ON c.parent_post_id = p.id
        JOIN person_likes_comment plc ON c.id = plc.comment_id
        GROUP BY p.container_forum_id
    ),
    -- Basic forum info together with moderator name
    moderator_info AS (
        SELECT f.id AS forum_id,
               f.title AS forum_title,
               f.creation_date AS forum_creation_date,
               m.first_name AS moderator_first_name,
               m.last_name  AS moderator_last_name
        FROM forum f
        JOIN person m ON f.moderator_person_id = m.id
    )
SELECT
    mi.forum_id,
    mi.forum_title,
    mi.forum_creation_date,
    mi.moderator_first_name,
    mi.moderator_last_name,
    COALESCE(fm.member_count, 0)       AS member_count,
    COALESCE(ft.forum_tag_count, 0)    AS forum_tag_count,
    COALESCE(ps.post_count, 0)         AS post_count,
    COALESCE(ps.avg_post_length, 0)    AS avg_post_length,
    COALESCE(pts.post_tag_count, 0)    AS post_tag_count,
    COALESCE(cs.comment_count, 0)      AS comment_count,
    COALESCE(pls.post_like_count, 0)   AS post_like_count,
    COALESCE(cls.comment_like_count, 0) AS comment_like_count
FROM moderator_info mi
LEFT JOIN forum_members      fm  ON mi.forum_id = fm.forum_id
LEFT JOIN forum_tags         ft  ON mi.forum_id = ft.forum_id
LEFT JOIN post_stats         ps  ON mi.forum_id = ps.forum_id
LEFT JOIN post_tag_stats     pts ON mi.forum_id = pts.forum_id
LEFT JOIN comment_stats      cs  ON mi.forum_id = cs.forum_id
LEFT JOIN post_likes_stats   pls ON mi.forum_id = pls.forum_id
LEFT JOIN comment_likes_stats cls ON mi.forum_id = cls.forum_id
ORDER BY mi.forum_id

WITH
    forum_posts AS (
        SELECT
            p.container_forum_id AS forum_id,
            COUNT(*) AS post_count,
            AVG(p.length) AS avg_post_length
        FROM post p
        GROUP BY p.container_forum_id
    ),
    forum_comments AS (
        SELECT
            p.container_forum_id AS forum_id,
            COUNT(*) AS comment_count,
            AVG(c.length) AS avg_comment_length
        FROM comment c
        JOIN post p ON c.parent_post_id = p.id
        GROUP BY p.container_forum_id
    ),
    forum_post_tags AS (
        SELECT
            p.container_forum_id AS forum_id,
            COUNT(DISTINCT pt.tag_id) AS distinct_post_tags
        FROM post_has_tag_tag pt
        JOIN post p ON pt.post_id = p.id
        GROUP BY p.container_forum_id
    ),
    forum_comment_tags AS (
        SELECT
            p.container_forum_id AS forum_id,
            COUNT(DISTINCT ct.tag_id) AS distinct_comment_tags
        FROM comment_has_tag_tag ct
        JOIN comment c ON ct.comment_id = c.id
        JOIN post p ON c.parent_post_id = p.id
        GROUP BY p.container_forum_id
    ),
    forum_members AS (
        SELECT
            fm.forum_id,
            COUNT(DISTINCT fm.person_id) AS member_count
        FROM forum_has_member_person fm
        GROUP BY fm.forum_id
    ),
    forum_post_likers AS (
        SELECT
            p.container_forum_id AS forum_id,
            COUNT(DISTINCT pl.person_id) AS post_like_user_count
        FROM person_likes_post pl
        JOIN post p ON pl.post_id = p.id
        GROUP BY p.container_forum_id
    ),
    forum_comment_likers AS (
        SELECT
            p.container_forum_id AS forum_id,
            COUNT(DISTINCT cl.person_id) AS comment_like_user_count
        FROM person_likes_comment cl
        JOIN comment c ON cl.comment_id = c.id
        JOIN post p ON c.parent_post_id = p.id
        GROUP BY p.container_forum_id
    )
SELECT
    f.id AS forum_id,
    f.title AS forum_title,
    CONCAT(p_mod.first_name, ' ', p_mod.last_name) AS moderator_name,
    COALESCE(fp.post_count, 0) AS post_count,
    COALESCE(fc.comment_count, 0) AS comment_count,
    COALESCE(fp.avg_post_length, 0) AS avg_post_length,
    COALESCE(fc.avg_comment_length, 0) AS avg_comment_length,
    COALESCE(fpt.distinct_post_tags, 0) AS distinct_post_tags,
    COALESCE(fct.distinct_comment_tags, 0) AS distinct_comment_tags,
    COALESCE(fm.member_count, 0) AS member_count,
    COALESCE(fpl.post_like_user_count, 0) AS post_like_user_count,
    COALESCE(fcl.comment_like_user_count, 0) AS comment_like_user_count
FROM forum f
LEFT JOIN person p_mod ON f.moderator_person_id = p_mod.id
LEFT JOIN forum_posts fp ON fp.forum_id = f.id
LEFT JOIN forum_comments fc ON fc.forum_id = f.id
LEFT JOIN forum_post_tags fpt ON fpt.forum_id = f.id
LEFT JOIN forum_comment_tags fct ON fct.forum_id = f.id
LEFT JOIN forum_members fm ON fm.forum_id = f.id
LEFT JOIN forum_post_likers fpl ON fpl.forum_id = f.id
LEFT JOIN forum_comment_likers fcl ON fcl.forum_id = f.id
ORDER BY post_count DESC
LIMIT 20

WITH
    forum_members AS (
        SELECT
            forum_id,
            COUNT(DISTINCT person_id) AS member_count
        FROM forum_has_member_person
        GROUP BY forum_id
    ),
    forum_tags AS (
        SELECT
            forum_id,
            COUNT(DISTINCT tag_id) AS tag_count
        FROM forum_has_tag_tag
        GROUP BY forum_id
    ),
    forum_posts AS (
        SELECT
            container_forum_id AS forum_id,
            COUNT(*) AS post_count,
            SUM(length) AS total_post_length
        FROM post
        GROUP BY container_forum_id
    ),
    forum_comments AS (
        SELECT
            p.container_forum_id AS forum_id,
            COUNT(c.id) AS comment_count,
            SUM(c.length) AS total_comment_length
        FROM comment c
        JOIN post p
            ON c.parent_post_id = p.id
        GROUP BY p.container_forum_id
    ),
    forum_likes AS (
        SELECT
            p.container_forum_id AS forum_id,
            COUNT(pl.person_id) AS total_likes,
            COUNT(DISTINCT pl.person_id) AS distinct_likers
        FROM person_likes_post pl
        JOIN post p
            ON pl.post_id = p.id
        GROUP BY p.container_forum_id
    ),
    forum_moderator AS (
        SELECT
            f.id AS forum_id,
            p.first_name AS moderator_first_name,
            p.last_name AS moderator_last_name
        FROM forum f
        JOIN person p
            ON f.moderator_person_id = p.id
    )
SELECT
    f.id AS forum_id,
    f.title AS forum_title,
    fm.moderator_first_name,
    fm.moderator_last_name,
    COALESCE(m.member_count, 0) AS member_count,
    COALESCE(t.tag_count, 0) AS tag_count,
    COALESCE(p.post_count, 0) AS post_count,
    COALESCE(p.total_post_length, 0) AS total_post_length,
    CASE WHEN COALESCE(p.post_count, 0) = 0 THEN 0
         ELSE p.total_post_length * 1.0 / p.post_count END AS avg_post_length,
    COALESCE(c.comment_count, 0) AS comment_count,
    COALESCE(c.total_comment_length, 0) AS total_comment_length,
    CASE WHEN COALESCE(c.comment_count, 0) = 0 THEN 0
         ELSE c.total_comment_length * 1.0 / c.comment_count END AS avg_comment_length,
    COALESCE(l.total_likes, 0) AS total_likes,
    COALESCE(l.distinct_likers, 0) AS distinct_likers,
    CASE WHEN COALESCE(p.post_count, 0) = 0 THEN 0
         ELSE COALESCE(l.total_likes, 0) * 1.0 / p.post_count END AS avg_likes_per_post
FROM forum f
LEFT JOIN forum_moderator fm
    ON f.id = fm.forum_id
LEFT JOIN forum_members m
    ON f.id = m.forum_id
LEFT JOIN forum_tags t
    ON f.id = t.forum_id
LEFT JOIN forum_posts p
    ON f.id = p.forum_id
LEFT JOIN forum_comments c
    ON f.id = c.forum_id
LEFT JOIN forum_likes l
    ON f.id = l.forum_id
ORDER BY f.id

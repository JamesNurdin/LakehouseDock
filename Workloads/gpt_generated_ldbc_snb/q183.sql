WITH
    post_stats AS (
        SELECT f.id AS forum_id,
               f.title AS forum_title,
               COUNT(p.id) AS post_count,
               AVG(p.length) AS avg_post_length
        FROM forum f
        LEFT JOIN post p
            ON p.container_forum_id = f.id
        GROUP BY f.id, f.title
    ),
    comment_stats AS (
        SELECT f.id AS forum_id,
               COUNT(c.id) AS comment_count,
               AVG(c.length) AS avg_comment_length
        FROM forum f
        LEFT JOIN post p
            ON p.container_forum_id = f.id
        LEFT JOIN comment c
            ON c.parent_post_id = p.id
        GROUP BY f.id
    ),
    post_like_stats AS (
        SELECT f.id AS forum_id,
               COUNT(pl.person_id) AS post_like_count
        FROM forum f
        LEFT JOIN post p
            ON p.container_forum_id = f.id
        LEFT JOIN person_likes_post pl
            ON pl.post_id = p.id
        GROUP BY f.id
    ),
    comment_like_stats AS (
        SELECT f.id AS forum_id,
               COUNT(cl.person_id) AS comment_like_count
        FROM forum f
        LEFT JOIN post p
            ON p.container_forum_id = f.id
        LEFT JOIN comment c
            ON c.parent_post_id = p.id
        LEFT JOIN person_likes_comment cl
            ON cl.comment_id = c.id
        GROUP BY f.id
    ),
    member_stats AS (
        SELECT f.id AS forum_id,
               COUNT(fm.person_id) AS member_count
        FROM forum f
        LEFT JOIN forum_has_member_person fm
            ON fm.forum_id = f.id
        GROUP BY f.id
    ),
    moderator_info AS (
        SELECT f.id AS forum_id,
               p.first_name AS moderator_first_name,
               p.last_name AS moderator_last_name
        FROM forum f
        LEFT JOIN person p
            ON p.id = f.moderator_person_id
    ),
    member_interest_stats AS (
        SELECT f.id AS forum_id,
               COUNT(DISTINCT pit.tag_id) AS distinct_member_interest_tag_count
        FROM forum f
        LEFT JOIN forum_has_member_person fm
            ON fm.forum_id = f.id
        LEFT JOIN person p
            ON p.id = fm.person_id
        LEFT JOIN person_has_interest_tag pit
            ON pit.person_id = p.id
        GROUP BY f.id
    )
SELECT
    ps.forum_id,
    ps.forum_title,
    ps.post_count,
    ps.avg_post_length,
    cs.comment_count,
    cs.avg_comment_length,
    pl.post_like_count,
    cl.comment_like_count,
    ms.member_count,
    mis.distinct_member_interest_tag_count,
    mi.moderator_first_name,
    mi.moderator_last_name
FROM post_stats ps
LEFT JOIN comment_stats cs
    ON cs.forum_id = ps.forum_id
LEFT JOIN post_like_stats pl
    ON pl.forum_id = ps.forum_id
LEFT JOIN comment_like_stats cl
    ON cl.forum_id = ps.forum_id
LEFT JOIN member_stats ms
    ON ms.forum_id = ps.forum_id
LEFT JOIN member_interest_stats mis
    ON mis.forum_id = ps.forum_id
LEFT JOIN moderator_info mi
    ON mi.forum_id = ps.forum_id
ORDER BY ps.post_count DESC
LIMIT 10

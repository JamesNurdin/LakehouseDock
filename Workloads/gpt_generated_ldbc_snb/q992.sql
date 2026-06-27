WITH
    /* Likes per post */
    post_likes AS (
        SELECT
            post_id,
            COUNT(DISTINCT person_id) AS like_cnt
        FROM person_likes_post
        GROUP BY post_id
    ),
    /* Likes per comment */
    comment_likes AS (
        SELECT
            comment_id,
            COUNT(DISTINCT person_id) AS like_cnt
        FROM person_likes_comment
        GROUP BY comment_id
    ),
    /* Basic forum information together with moderator details */
    forum_base AS (
        SELECT
            f.id AS forum_id,
            f.title AS forum_title,
            mod.id AS moderator_id,
            mod.first_name AS moderator_first_name,
            mod.last_name AS moderator_last_name,
            city.name AS moderator_city
        FROM forum f
        LEFT JOIN person mod
            ON f.moderator_person_id = mod.id
        LEFT JOIN place city
            ON mod.location_city_id = city.id
    ),
    /* Aggregated post statistics per forum */
    post_stats AS (
        SELECT
            p.container_forum_id AS forum_id,
            COUNT(DISTINCT p.id) AS total_posts,
            COALESCE(SUM(pl.like_cnt), 0) AS total_post_likes
        FROM post p
        LEFT JOIN post_likes pl
            ON pl.post_id = p.id
        GROUP BY p.container_forum_id
    ),
    /* Aggregated comment statistics per forum */
    comment_stats AS (
        SELECT
            p.container_forum_id AS forum_id,
            COUNT(DISTINCT c.id) AS total_comments,
            COALESCE(SUM(cl.like_cnt), 0) AS total_comment_likes
        FROM comment c
        JOIN post p
            ON c.parent_post_id = p.id
        LEFT JOIN comment_likes cl
            ON cl.comment_id = c.id
        GROUP BY p.container_forum_id
    ),
    /* Distinct active users (post or comment creators) per forum */
    active_user_stats AS (
        SELECT
            forum_id,
            COUNT(DISTINCT user_id) AS distinct_active_users
        FROM (
            SELECT
                p.container_forum_id AS forum_id,
                p.creator_person_id AS user_id
            FROM post p
            UNION ALL
            SELECT
                p.container_forum_id AS forum_id,
                c.creator_person_id AS user_id
            FROM comment c
            JOIN post p
                ON c.parent_post_id = p.id
        ) fu
        GROUP BY forum_id
    )
SELECT
    fb.forum_id,
    fb.forum_title,
    fb.moderator_first_name,
    fb.moderator_last_name,
    fb.moderator_city,
    COALESCE(ps.total_posts, 0) AS total_posts,
    COALESCE(cs.total_comments, 0) AS total_comments,
    CASE WHEN COALESCE(ps.total_posts, 0) = 0 THEN 0
         ELSE COALESCE(ps.total_post_likes, 0) / COALESCE(ps.total_posts, 1)
    END AS avg_likes_per_post,
    CASE WHEN COALESCE(cs.total_comments, 0) = 0 THEN 0
         ELSE COALESCE(cs.total_comment_likes, 0) / COALESCE(cs.total_comments, 1)
    END AS avg_likes_per_comment,
    COALESCE(au.distinct_active_users, 0) AS distinct_active_users
FROM forum_base fb
LEFT JOIN post_stats ps
    ON fb.forum_id = ps.forum_id
LEFT JOIN comment_stats cs
    ON fb.forum_id = cs.forum_id
LEFT JOIN active_user_stats au
    ON fb.forum_id = au.forum_id
ORDER BY total_posts DESC
LIMIT 10

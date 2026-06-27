WITH posts_agg AS (
    SELECT
        p.container_forum_id AS forum_id,
        count(*) AS post_count,
        avg(p.length) AS avg_post_length
    FROM post p
    GROUP BY p.container_forum_id
),
comments_agg AS (
    SELECT
        f.id AS forum_id,
        count(*) AS comment_count,
        avg(c.length) AS avg_comment_length
    FROM comment c
    JOIN post p ON c.parent_post_id = p.id
    JOIN forum f ON p.container_forum_id = f.id
    GROUP BY f.id
),
likes_posts_agg AS (
    SELECT
        p.container_forum_id AS forum_id,
        count(*) AS total_likes_on_posts
    FROM person_likes_post plp
    JOIN post p ON plp.post_id = p.id
    GROUP BY p.container_forum_id
),
likes_comments_agg AS (
    SELECT
        f.id AS forum_id,
        count(*) AS total_likes_on_comments
    FROM person_likes_comment plc
    JOIN comment c ON plc.comment_id = c.id
    JOIN post p ON c.parent_post_id = p.id
    JOIN forum f ON p.container_forum_id = f.id
    GROUP BY f.id
),
members_agg AS (
    SELECT
        fm.forum_id AS forum_id,
        count(DISTINCT fm.person_id) AS member_count
    FROM forum_has_member_person fm
    GROUP BY fm.forum_id
),
participants_agg AS (
    SELECT
        forum_id,
        count(DISTINCT person_id) AS participant_count
    FROM (
        SELECT
            p.container_forum_id AS forum_id,
            p.creator_person_id AS person_id
        FROM post p
        UNION ALL
        SELECT
            f.id AS forum_id,
            c.creator_person_id AS person_id
        FROM comment c
        JOIN post p ON c.parent_post_id = p.id
        JOIN forum f ON p.container_forum_id = f.id
    ) participants
    GROUP BY forum_id
)
SELECT
    f.id AS forum_id,
    f.title AS forum_title,
    coalesce(pf.post_count, 0) AS post_count,
    coalesce(cf.comment_count, 0) AS comment_count,
    coalesce(pf.avg_post_length, 0) AS avg_post_length,
    coalesce(cf.avg_comment_length, 0) AS avg_comment_length,
    coalesce(lp.total_likes_on_posts, 0) AS total_likes_on_posts,
    coalesce(lc.total_likes_on_comments, 0) AS total_likes_on_comments,
    coalesce(m.member_count, 0) AS member_count,
    coalesce(pa.participant_count, 0) AS participant_count,
    (coalesce(pf.post_count, 0) + coalesce(cf.comment_count, 0) + coalesce(lp.total_likes_on_posts, 0) + coalesce(lc.total_likes_on_comments, 0)) AS total_activity
FROM forum f
LEFT JOIN posts_agg pf ON f.id = pf.forum_id
LEFT JOIN comments_agg cf ON f.id = cf.forum_id
LEFT JOIN likes_posts_agg lp ON f.id = lp.forum_id
LEFT JOIN likes_comments_agg lc ON f.id = lc.forum_id
LEFT JOIN members_agg m ON f.id = m.forum_id
LEFT JOIN participants_agg pa ON f.id = pa.forum_id
ORDER BY total_activity DESC
LIMIT 10

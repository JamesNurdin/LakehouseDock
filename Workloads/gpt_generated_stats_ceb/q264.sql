WITH posts_owned AS (
    SELECT
        owneruserid AS user_id,
        COUNT(*) AS posts_owned,
        SUM(score) AS total_post_score,
        SUM(viewcount) AS total_post_views,
        SUM(answercount) AS total_answers,
        SUM(favoritecount) AS total_favorites
    FROM posts
    GROUP BY owneruserid
),
posts_edited AS (
    SELECT
        lasteditoruserid AS user_id,
        COUNT(*) AS posts_edited
    FROM posts
    GROUP BY lasteditoruserid
),
comments_by_user AS (
    SELECT
        userid AS user_id,
        COUNT(*) AS comments_made
    FROM comments
    GROUP BY userid
),
votes_by_user AS (
    SELECT
        userid AS user_id,
        COUNT(*) AS votes_cast
    FROM votes
    GROUP BY userid
),
votes_received AS (
    SELECT
        p.owneruserid AS user_id,
        COUNT(*) AS votes_received
    FROM votes v
    JOIN posts p
        ON v.postid = p.id
    GROUP BY p.owneruserid
),
badges_by_user AS (
    SELECT
        userid AS user_id,
        COUNT(*) AS badges_earned
    FROM badges
    GROUP BY userid
),
tags_used AS (
    SELECT
        p.owneruserid AS user_id,
        COUNT(DISTINCT t.id) AS tags_used
    FROM tags t
    JOIN posts p
        ON t.excerptpostid = p.id
    GROUP BY p.owneruserid
)
SELECT
    u.id AS user_id,
    u.reputation,
    COALESCE(po.posts_owned, 0) AS posts_owned,
    COALESCE(pe.posts_edited, 0) AS posts_edited,
    COALESCE(cb.comments_made, 0) AS comments_made,
    COALESCE(vb.votes_cast, 0) AS votes_cast,
    COALESCE(vr.votes_received, 0) AS votes_received,
    COALESCE(bb.badges_earned, 0) AS badges_earned,
    COALESCE(tu.tags_used, 0) AS tags_used,
    COALESCE(po.total_post_score, 0) AS total_post_score,
    COALESCE(po.total_post_views, 0) AS total_post_views,
    COALESCE(po.total_answers, 0) AS total_answers,
    COALESCE(po.total_favorites, 0) AS total_favorites
FROM users u
LEFT JOIN posts_owned po
    ON po.user_id = u.id
LEFT JOIN posts_edited pe
    ON pe.user_id = u.id
LEFT JOIN comments_by_user cb
    ON cb.user_id = u.id
LEFT JOIN votes_by_user vb
    ON vb.user_id = u.id
LEFT JOIN votes_received vr
    ON vr.user_id = u.id
LEFT JOIN badges_by_user bb
    ON bb.user_id = u.id
LEFT JOIN tags_used tu
    ON tu.user_id = u.id
ORDER BY total_post_score DESC
LIMIT 50

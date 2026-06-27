WITH user_posts AS (
    SELECT
        u.id AS user_id,
        u.reputation,
        COUNT(p.id) AS post_count,
        COALESCE(SUM(p.score), 0) AS total_post_score,
        COALESCE(AVG(p.score), 0) AS avg_post_score
    FROM users u
    LEFT JOIN posts p
        ON p.owneruserid = u.id
    GROUP BY u.id, u.reputation
),
post_comments AS (
    SELECT
        p.owneruserid AS user_id,
        COUNT(c.id) AS comment_on_posts_count
    FROM posts p
    LEFT JOIN comments c
        ON c.postid = p.id
    GROUP BY p.owneruserid
),
post_votes AS (
    SELECT
        p.owneruserid AS user_id,
        COUNT(v.id) AS vote_on_posts_count,
        COALESCE(SUM(CASE WHEN v.votetypeid = 2 THEN 1 ELSE 0 END), 0) AS upvote_count,
        COALESCE(SUM(CASE WHEN v.votetypeid = 3 THEN 1 ELSE 0 END), 0) AS downvote_count
    FROM posts p
    LEFT JOIN votes v
        ON v.postid = p.id
    GROUP BY p.owneruserid
),
user_badges AS (
    SELECT
        b.userid AS user_id,
        COUNT(b.id) AS badge_count
    FROM badges b
    GROUP BY b.userid
),
user_comments AS (
    SELECT
        c.userid AS user_id,
        COUNT(c.id) AS comment_by_user_count
    FROM comments c
    GROUP BY c.userid
),
user_votes_cast AS (
    SELECT
        v.userid AS user_id,
        COUNT(v.id) AS votes_cast_count
    FROM votes v
    GROUP BY v.userid
),
user_posthistory AS (
    SELECT
        ph.userid AS user_id,
        COUNT(ph.id) AS posthistory_count
    FROM posthistory ph
    GROUP BY ph.userid
),
user_postlinks AS (
    SELECT
        p.owneruserid AS user_id,
        COUNT(pl.id) AS postlink_count
    FROM posts p
    LEFT JOIN postlinks pl
        ON pl.postid = p.id
    GROUP BY p.owneruserid
),
user_tags AS (
    SELECT
        p.owneruserid AS user_id,
        COUNT(t.id) AS tag_excerpt_count
    FROM posts p
    LEFT JOIN tags t
        ON t.excerptpostid = p.id
    GROUP BY p.owneruserid
)
SELECT
    up.user_id,
    up.reputation,
    up.post_count,
    up.total_post_score,
    up.avg_post_score,
    COALESCE(pc.comment_on_posts_count, 0) AS comment_on_posts_count,
    COALESCE(pv.vote_on_posts_count, 0) AS vote_on_posts_count,
    COALESCE(pv.upvote_count, 0) AS upvote_count,
    COALESCE(pv.downvote_count, 0) AS downvote_count,
    COALESCE(ub.badge_count, 0) AS badge_count,
    COALESCE(uc.comment_by_user_count, 0) AS comment_by_user_count,
    COALESCE(uvc.votes_cast_count, 0) AS votes_cast_count,
    COALESCE(uph.posthistory_count, 0) AS posthistory_count,
    COALESCE(upl.postlink_count, 0) AS postlink_count,
    COALESCE(ut.tag_excerpt_count, 0) AS tag_excerpt_count
FROM user_posts up
LEFT JOIN post_comments pc
    ON pc.user_id = up.user_id
LEFT JOIN post_votes pv
    ON pv.user_id = up.user_id
LEFT JOIN user_badges ub
    ON ub.user_id = up.user_id
LEFT JOIN user_comments uc
    ON uc.user_id = up.user_id
LEFT JOIN user_votes_cast uvc
    ON uvc.user_id = up.user_id
LEFT JOIN user_posthistory uph
    ON uph.user_id = up.user_id
LEFT JOIN user_postlinks upl
    ON upl.user_id = up.user_id
LEFT JOIN user_tags ut
    ON ut.user_id = up.user_id
ORDER BY up.total_post_score DESC
LIMIT 100

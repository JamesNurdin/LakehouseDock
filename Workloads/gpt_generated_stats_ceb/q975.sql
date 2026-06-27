WITH user_posts AS (
    SELECT
        u.id AS user_id,
        u.reputation,
        u.creationdate,
        COUNT(p.id) AS post_count,
        COALESCE(SUM(p.score), 0) AS total_post_score,
        COALESCE(SUM(p.viewcount), 0) AS total_viewcount,
        COALESCE(SUM(p.answercount), 0) AS total_answercount,
        COALESCE(SUM(p.commentcount), 0) AS total_commentcount,
        COALESCE(SUM(p.favoritecount), 0) AS total_favoritecount
    FROM users u
    LEFT JOIN posts p
        ON p.owneruserid = u.id
    GROUP BY u.id, u.reputation, u.creationdate
),
user_comments AS (
    SELECT
        u.id AS user_id,
        COUNT(c.id) AS comment_made_count,
        COALESCE(AVG(c.score), 0) AS avg_comment_score,
        COALESCE(SUM(c.score), 0) AS total_comment_score
    FROM users u
    LEFT JOIN comments c
        ON c.userid = u.id
    GROUP BY u.id
),
user_badges AS (
    SELECT
        u.id AS user_id,
        COUNT(b.id) AS badge_count
    FROM users u
    LEFT JOIN badges b
        ON b.userid = u.id
    GROUP BY u.id
),
user_votes_cast AS (
    SELECT
        u.id AS user_id,
        COUNT(v.id) AS votes_cast_count,
        COALESCE(SUM(v.bountyamount), 0) AS total_bounty_given
    FROM users u
    LEFT JOIN votes v
        ON v.userid = u.id
    GROUP BY u.id
),
user_votes_received AS (
    SELECT
        u.id AS user_id,
        COUNT(v.id) AS votes_received_count
    FROM users u
    LEFT JOIN posts p
        ON p.owneruserid = u.id
    LEFT JOIN votes v
        ON v.postid = p.id
    GROUP BY u.id
),
user_posthistory AS (
    SELECT
        u.id AS user_id,
        COUNT(ph.id) AS posthistory_count
    FROM users u
    LEFT JOIN posthistory ph
        ON ph.userid = u.id
    GROUP BY u.id
),
user_postlinks AS (
    SELECT
        u.id AS user_id,
        COUNT(pl.id) AS postlink_count
    FROM users u
    LEFT JOIN posts p
        ON p.owneruserid = u.id
    LEFT JOIN postlinks pl
        ON pl.postid = p.id
    GROUP BY u.id
),
user_tag_excerpts AS (
    SELECT
        u.id AS user_id,
        COUNT(DISTINCT t.id) AS distinct_tag_excerpt_count
    FROM users u
    LEFT JOIN posts p
        ON p.owneruserid = u.id
    LEFT JOIN tags t
        ON t.excerptpostid = p.id
    GROUP BY u.id
)
SELECT
    up.user_id,
    up.reputation,
    up.creationdate,
    up.post_count,
    up.total_post_score,
    up.total_viewcount,
    up.total_answercount,
    up.total_commentcount,
    up.total_favoritecount,
    uc.comment_made_count,
    uc.avg_comment_score,
    ub.badge_count,
    uv_cast.votes_cast_count,
    uv_cast.total_bounty_given,
    uv_recv.votes_received_count,
    uph.posthistory_count,
    upl.postlink_count,
    ut.distinct_tag_excerpt_count
FROM user_posts up
LEFT JOIN user_comments uc
    ON uc.user_id = up.user_id
LEFT JOIN user_badges ub
    ON ub.user_id = up.user_id
LEFT JOIN user_votes_cast uv_cast
    ON uv_cast.user_id = up.user_id
LEFT JOIN user_votes_received uv_recv
    ON uv_recv.user_id = up.user_id
LEFT JOIN user_posthistory uph
    ON uph.user_id = up.user_id
LEFT JOIN user_postlinks upl
    ON upl.user_id = up.user_id
LEFT JOIN user_tag_excerpts ut
    ON ut.user_id = up.user_id
ORDER BY up.reputation DESC
LIMIT 20

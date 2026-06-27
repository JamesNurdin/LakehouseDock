WITH user_posts AS (
    SELECT
        u.id AS userid,
        COUNT(p.id) AS post_count,
        COALESCE(SUM(p.score), 0) AS total_post_score,
        COALESCE(SUM(p.viewcount), 0) AS total_views,
        COALESCE(AVG(p.answercount), 0) AS avg_answer_count
    FROM users u
    LEFT JOIN posts p
        ON p.owneruserid = u.id
    GROUP BY u.id
),
user_comments AS (
    SELECT
        u.id AS userid,
        COUNT(c.id) AS comment_count,
        COALESCE(SUM(c.score), 0) AS total_comment_score
    FROM users u
    LEFT JOIN comments c
        ON c.userid = u.id
    GROUP BY u.id
),
user_votes AS (
    SELECT
        u.id AS userid,
        COUNT(v.id) AS vote_cast_count,
        COALESCE(SUM(CASE WHEN v.votetypeid = 1 THEN 1 ELSE 0 END), 0) AS upvote_cast,
        COALESCE(SUM(CASE WHEN v.votetypeid = 2 THEN 1 ELSE 0 END), 0) AS downvote_cast
    FROM users u
    LEFT JOIN votes v
        ON v.userid = u.id
    GROUP BY u.id
),
user_badges AS (
    SELECT
        u.id AS userid,
        COUNT(b.id) AS badge_count
    FROM users u
    LEFT JOIN badges b
        ON b.userid = u.id
    GROUP BY u.id
),
user_tags AS (
    SELECT
        u.id AS userid,
        COUNT(DISTINCT t.id) AS distinct_tag_count
    FROM users u
    LEFT JOIN posts p
        ON p.owneruserid = u.id
    LEFT JOIN tags t
        ON t.excerptpostid = p.id
    GROUP BY u.id
),
user_postlinks AS (
    SELECT
        u.id AS userid,
        COUNT(pl.id) AS postlink_outgoing_count
    FROM users u
    LEFT JOIN posts p
        ON p.owneruserid = u.id
    LEFT JOIN postlinks pl
        ON pl.postid = p.id
    GROUP BY u.id
),
user_posthistory AS (
    SELECT
        u.id AS userid,
        COUNT(ph.id) AS posthistory_count
    FROM users u
    LEFT JOIN posthistory ph
        ON ph.userid = u.id
    LEFT JOIN posts p
        ON ph.posthistorytypeid = p.id
    GROUP BY u.id
)
SELECT
    u.id,
    u.reputation,
    u.creationdate,
    up.post_count,
    up.total_post_score,
    up.total_views,
    up.avg_answer_count,
    uc.comment_count,
    uc.total_comment_score,
    uv.vote_cast_count,
    uv.upvote_cast,
    uv.downvote_cast,
    ub.badge_count,
    ut.distinct_tag_count,
    upl.postlink_outgoing_count,
    uph.posthistory_count
FROM users u
LEFT JOIN user_posts up
    ON up.userid = u.id
LEFT JOIN user_comments uc
    ON uc.userid = u.id
LEFT JOIN user_votes uv
    ON uv.userid = u.id
LEFT JOIN user_badges ub
    ON ub.userid = u.id
LEFT JOIN user_tags ut
    ON ut.userid = u.id
LEFT JOIN user_postlinks upl
    ON upl.userid = u.id
LEFT JOIN user_posthistory uph
    ON uph.userid = u.id
ORDER BY u.reputation DESC
LIMIT 100

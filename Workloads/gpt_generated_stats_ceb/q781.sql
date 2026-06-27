WITH user_posts AS (
    SELECT
        u.id,
        u.reputation,
        COUNT(p.id) AS post_count,
        SUM(p.score) AS total_post_score,
        AVG(p.score) AS avg_post_score,
        SUM(p.favoritecount) AS total_favoritecount,
        SUM(p.viewcount) AS total_viewcount,
        SUM(p.commentcount) AS total_commentcount,
        SUM(p.answercount) AS total_answercount
    FROM users u
    LEFT JOIN posts p ON p.owneruserid = u.id
    GROUP BY u.id, u.reputation
),
user_comments AS (
    SELECT
        u.id,
        COUNT(c.id) AS comment_count,
        SUM(c.score) AS total_comment_score
    FROM users u
    LEFT JOIN comments c ON c.userid = u.id
    GROUP BY u.id
),
user_votes_cast AS (
    SELECT
        u.id,
        COUNT(v.id) AS votes_cast,
        SUM(COALESCE(v.bountyamount, 0)) AS total_bounty_given
    FROM users u
    LEFT JOIN votes v ON v.userid = u.id
    GROUP BY u.id
),
user_votes_received AS (
    SELECT
        u.id,
        COUNT(v.id) AS votes_received
    FROM users u
    LEFT JOIN posts p ON p.owneruserid = u.id
    LEFT JOIN votes v ON v.postid = p.id
    GROUP BY u.id
),
user_badges AS (
    SELECT
        u.id,
        COUNT(b.id) AS badge_count
    FROM users u
    LEFT JOIN badges b ON b.userid = u.id
    GROUP BY u.id
),
user_tags AS (
    SELECT
        u.id,
        COUNT(t.id) AS tag_count
    FROM users u
    LEFT JOIN posts p ON p.owneruserid = u.id
    LEFT JOIN tags t ON t.excerptpostid = p.id
    GROUP BY u.id
),
user_postlinks AS (
    SELECT
        u.id,
        COUNT(pl.id) AS postlink_count
    FROM users u
    LEFT JOIN posts p ON p.owneruserid = u.id
    LEFT JOIN postlinks pl ON pl.postid = p.id
    GROUP BY u.id
),
user_posthistory AS (
    SELECT
        u.id,
        COUNT(ph.id) AS posthistory_count
    FROM users u
    LEFT JOIN posthistory ph ON ph.userid = u.id
    LEFT JOIN posts p ON ph.posthistorytypeid = p.id
    GROUP BY u.id
)
SELECT
    up.id,
    up.reputation,
    up.post_count,
    up.total_post_score,
    up.avg_post_score,
    up.total_favoritecount,
    up.total_viewcount,
    up.total_commentcount,
    up.total_answercount,
    uc.comment_count,
    uc.total_comment_score,
    vc.votes_cast,
    vc.total_bounty_given,
    vr.votes_received,
    ub.badge_count,
    ut.tag_count,
    upl.postlink_count,
    uph.posthistory_count
FROM user_posts up
LEFT JOIN user_comments uc ON uc.id = up.id
LEFT JOIN user_votes_cast vc ON vc.id = up.id
LEFT JOIN user_votes_received vr ON vr.id = up.id
LEFT JOIN user_badges ub ON ub.id = up.id
LEFT JOIN user_tags ut ON ut.id = up.id
LEFT JOIN user_postlinks upl ON upl.id = up.id
LEFT JOIN user_posthistory uph ON uph.id = up.id
ORDER BY up.post_count DESC
LIMIT 100

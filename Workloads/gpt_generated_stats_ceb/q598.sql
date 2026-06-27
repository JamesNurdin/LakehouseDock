WITH user_posts AS (
    SELECT
        u.id AS user_id,
        COUNT(p.id) AS post_count,
        COALESCE(SUM(p.score), 0) AS post_score_sum,
        COALESCE(SUM(p.viewcount), 0) AS post_viewcount_sum,
        COALESCE(SUM(p.answercount), 0) AS post_answercount_sum,
        COALESCE(SUM(p.commentcount), 0) AS post_commentcount_sum,
        COALESCE(SUM(p.favoritecount), 0) AS post_favoritecount_sum
    FROM users u
    LEFT JOIN posts p
        ON p.owneruserid = u.id
    GROUP BY u.id
),
user_comments AS (
    SELECT
        u.id AS user_id,
        COUNT(c.id) AS comment_count,
        COALESCE(SUM(c.score), 0) AS comment_score_sum
    FROM users u
    LEFT JOIN comments c
        ON c.userid = u.id
    GROUP BY u.id
),
user_votes_cast AS (
    SELECT
        u.id AS user_id,
        COUNT(v.id) AS votes_cast_count
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
user_badges AS (
    SELECT
        u.id AS user_id,
        COUNT(b.id) AS badge_count
    FROM users u
    LEFT JOIN badges b
        ON b.userid = u.id
    GROUP BY u.id
),
user_postlinks AS (
    SELECT
        u.id AS user_id,
        COUNT(DISTINCT pl.id) AS postlink_count
    FROM users u
    LEFT JOIN posts p
        ON p.owneruserid = u.id
    LEFT JOIN postlinks pl
        ON pl.postid = p.id OR pl.relatedpostid = p.id
    GROUP BY u.id
),
user_tags AS (
    SELECT
        u.id AS user_id,
        COUNT(DISTINCT t.id) AS tag_count
    FROM users u
    LEFT JOIN posts p
        ON p.owneruserid = u.id
    LEFT JOIN tags t
        ON t.excerptpostid = p.id
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
user_posthistory_type AS (
    SELECT
        u.id AS user_id,
        COUNT(ph.id) AS posthistory_type_count
    FROM users u
    LEFT JOIN posts p
        ON p.owneruserid = u.id
    LEFT JOIN posthistory ph
        ON ph.posthistorytypeid = p.id
    GROUP BY u.id
)
SELECT
    u.id,
    u.reputation,
    u.creationdate,
    u.views,
    u.upvotes,
    u.downvotes,
    COALESCE(up.post_count, 0) AS post_count,
    COALESCE(up.post_score_sum, 0) AS post_score_sum,
    COALESCE(up.post_viewcount_sum, 0) AS post_viewcount_sum,
    COALESCE(up.post_answercount_sum, 0) AS post_answercount_sum,
    COALESCE(up.post_commentcount_sum, 0) AS post_commentcount_sum,
    COALESCE(up.post_favoritecount_sum, 0) AS post_favoritecount_sum,
    COALESCE(uc.comment_count, 0) AS comment_count,
    COALESCE(uc.comment_score_sum, 0) AS comment_score_sum,
    COALESCE(uvc.votes_cast_count, 0) AS votes_cast_count,
    COALESCE(uvr.votes_received_count, 0) AS votes_received_count,
    COALESCE(ub.badge_count, 0) AS badge_count,
    COALESCE(upl.postlink_count, 0) AS postlink_count,
    COALESCE(ut.tag_count, 0) AS tag_count,
    COALESCE(uph.posthistory_count, 0) AS posthistory_count,
    COALESCE(upht.posthistory_type_count, 0) AS posthistory_type_count
FROM users u
LEFT JOIN user_posts up ON up.user_id = u.id
LEFT JOIN user_comments uc ON uc.user_id = u.id
LEFT JOIN user_votes_cast uvc ON uvc.user_id = u.id
LEFT JOIN user_votes_received uvr ON uvr.user_id = u.id
LEFT JOIN user_badges ub ON ub.user_id = u.id
LEFT JOIN user_postlinks upl ON upl.user_id = u.id
LEFT JOIN user_tags ut ON ut.user_id = u.id
LEFT JOIN user_posthistory uph ON uph.user_id = u.id
LEFT JOIN user_posthistory_type upht ON upht.user_id = u.id
ORDER BY post_score_sum DESC
LIMIT 100

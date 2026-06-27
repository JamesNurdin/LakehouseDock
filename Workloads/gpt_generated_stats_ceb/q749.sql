WITH user_posts AS (
    SELECT
        owneruserid AS userid,
        COUNT(*) AS post_count,
        SUM(score) AS post_score_sum,
        AVG(score) AS post_score_avg,
        SUM(answercount) AS answer_total,
        SUM(commentcount) AS comment_total,
        SUM(viewcount) AS view_total,
        SUM(favoritecount) AS favorite_total
    FROM posts
    GROUP BY owneruserid
),
user_comments AS (
    SELECT
        userid,
        COUNT(*) AS comment_count,
        SUM(score) AS comment_score_sum
    FROM comments
    GROUP BY userid
),
user_votes_cast AS (
    SELECT
        userid,
        COUNT(*) AS votes_cast
    FROM votes
    GROUP BY userid
),
votes_received AS (
    SELECT
        p.owneruserid AS userid,
        COUNT(*) AS votes_received
    FROM votes v
    JOIN posts p ON v.postid = p.id
    GROUP BY p.owneruserid
),
user_badges AS (
    SELECT
        userid,
        COUNT(*) AS badge_count
    FROM badges
    GROUP BY userid
),
user_edits AS (
    SELECT
        userid,
        COUNT(*) AS edit_count
    FROM posthistory
    GROUP BY userid
),
user_postlinks AS (
    SELECT
        p.owneruserid AS userid,
        COUNT(*) AS postlink_count
    FROM postlinks pl
    JOIN posts p ON pl.postid = p.id
    GROUP BY p.owneruserid
),
user_tags AS (
    SELECT
        p.owneruserid AS userid,
        COUNT(DISTINCT t.id) AS tag_count
    FROM tags t
    JOIN posts p ON t.excerptpostid = p.id
    GROUP BY p.owneruserid
),
user_metrics AS (
    SELECT
        u.id AS user_id,
        u.reputation,
        COALESCE(up.post_count, 0) AS post_count,
        COALESCE(up.post_score_sum, 0) AS post_score_sum,
        COALESCE(up.post_score_avg, 0.0) AS post_score_avg,
        COALESCE(up.answer_total, 0) AS answer_total,
        COALESCE(up.comment_total, 0) AS comment_total,
        COALESCE(up.view_total, 0) AS view_total,
        COALESCE(up.favorite_total, 0) AS favorite_total,
        COALESCE(uc.comment_count, 0) AS comment_count,
        COALESCE(uc.comment_score_sum, 0) AS comment_score_sum,
        COALESCE(uvc.votes_cast, 0) AS votes_cast,
        COALESCE(vr.votes_received, 0) AS votes_received,
        COALESCE(ub.badge_count, 0) AS badge_count,
        COALESCE(ue.edit_count, 0) AS edit_count,
        COALESCE(upL.postlink_count, 0) AS postlink_count,
        COALESCE(ut.tag_count, 0) AS tag_count
    FROM users u
    LEFT JOIN user_posts up          ON u.id = up.userid
    LEFT JOIN user_comments uc       ON u.id = uc.userid
    LEFT JOIN user_votes_cast uvc    ON u.id = uvc.userid
    LEFT JOIN votes_received vr      ON u.id = vr.userid
    LEFT JOIN user_badges ub         ON u.id = ub.userid
    LEFT JOIN user_edits ue          ON u.id = ue.userid
    LEFT JOIN user_postlinks upL     ON u.id = upL.userid
    LEFT JOIN user_tags ut           ON u.id = ut.userid
)
SELECT
    user_id,
    reputation,
    post_count,
    post_score_sum,
    post_score_avg,
    answer_total,
    comment_total,
    view_total,
    favorite_total,
    comment_count,
    comment_score_sum,
    votes_cast,
    votes_received,
    badge_count,
    edit_count,
    postlink_count,
    tag_count,
    RANK() OVER (ORDER BY post_score_sum DESC) AS post_score_rank
FROM user_metrics
WHERE post_count > 0
ORDER BY post_score_sum DESC
LIMIT 100

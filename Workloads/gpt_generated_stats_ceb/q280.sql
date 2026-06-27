WITH user_posts AS (
    SELECT
        p.owneruserid AS user_id,
        COUNT(*) AS post_count,
        COALESCE(SUM(p.score), 0) AS post_score_sum,
        COALESCE(SUM(p.viewcount), 0) AS post_view_sum,
        COALESCE(SUM(p.answercount), 0) AS post_answer_sum,
        COALESCE(SUM(p.commentcount), 0) AS post_comment_sum,
        COALESCE(SUM(p.favoritecount), 0) AS post_favorite_sum
    FROM posts p
    GROUP BY p.owneruserid
),
user_comments AS (
    SELECT
        c.userid AS user_id,
        COUNT(*) AS comment_count,
        COALESCE(SUM(c.score), 0) AS comment_score_sum
    FROM comments c
    GROUP BY c.userid
),
user_votes_cast AS (
    SELECT
        v.userid AS user_id,
        COUNT(*) AS votes_cast_count,
        COUNT(CASE WHEN v.votetypeid = 1 THEN 1 END) AS upvote_cast,
        COUNT(CASE WHEN v.votetypeid = 2 THEN 1 END) AS downvote_cast,
        COALESCE(SUM(v.bountyamount), 0) AS bounty_given_sum
    FROM votes v
    GROUP BY v.userid
),
user_votes_received AS (
    SELECT
        p.owneruserid AS user_id,
        COUNT(*) AS votes_received_count,
        COUNT(CASE WHEN v.votetypeid = 1 THEN 1 END) AS upvote_received,
        COUNT(CASE WHEN v.votetypeid = 2 THEN 1 END) AS downvote_received,
        COALESCE(SUM(v.bountyamount), 0) AS bounty_received_sum
    FROM posts p
    JOIN votes v ON v.postid = p.id
    GROUP BY p.owneruserid
),
user_badges AS (
    SELECT
        b.userid AS user_id,
        COUNT(*) AS badge_count
    FROM badges b
    GROUP BY b.userid
),
user_tags AS (
    SELECT
        p.owneruserid AS user_id,
        COUNT(DISTINCT t.id) AS tag_count
    FROM tags t
    JOIN posts p ON t.excerptpostid = p.id
    GROUP BY p.owneruserid
),
user_posthistory AS (
    SELECT
        ph.userid AS user_id,
        COUNT(*) AS posthistory_count
    FROM posthistory ph
    GROUP BY ph.userid
)
SELECT
    u.id AS user_id,
    u.reputation,
    u.creationdate,
    COALESCE(up.post_count, 0) AS post_count,
    COALESCE(up.post_score_sum, 0) AS post_score_sum,
    COALESCE(up.post_view_sum, 0) AS post_view_sum,
    COALESCE(up.post_answer_sum, 0) AS post_answer_sum,
    COALESCE(up.post_comment_sum, 0) AS post_comment_sum,
    COALESCE(up.post_favorite_sum, 0) AS post_favorite_sum,
    COALESCE(uc.comment_count, 0) AS comment_count,
    COALESCE(uc.comment_score_sum, 0) AS comment_score_sum,
    COALESCE(uvc.votes_cast_count, 0) AS votes_cast_count,
    COALESCE(uvc.upvote_cast, 0) AS upvote_cast,
    COALESCE(uvc.downvote_cast, 0) AS downvote_cast,
    COALESCE(uvc.bounty_given_sum, 0) AS bounty_given_sum,
    COALESCE(uvr.votes_received_count, 0) AS votes_received_count,
    COALESCE(uvr.upvote_received, 0) AS upvote_received,
    COALESCE(uvr.downvote_received, 0) AS downvote_received,
    COALESCE(uvr.bounty_received_sum, 0) AS bounty_received_sum,
    COALESCE(ub.badge_count, 0) AS badge_count,
    COALESCE(ut.tag_count, 0) AS tag_count,
    COALESCE(uph.posthistory_count, 0) AS posthistory_count
FROM users u
LEFT JOIN user_posts up ON up.user_id = u.id
LEFT JOIN user_comments uc ON uc.user_id = u.id
LEFT JOIN user_votes_cast uvc ON uvc.user_id = u.id
LEFT JOIN user_votes_received uvr ON uvr.user_id = u.id
LEFT JOIN user_badges ub ON ub.user_id = u.id
LEFT JOIN user_tags ut ON ut.user_id = u.id
LEFT JOIN user_posthistory uph ON uph.user_id = u.id
ORDER BY u.reputation DESC
LIMIT 100

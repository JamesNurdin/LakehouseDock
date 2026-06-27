WITH user_posts AS (
    SELECT
        p.owneruserid AS user_id,
        COUNT(p.id) AS post_count,
        COALESCE(SUM(p.score), 0) AS total_post_score,
        AVG(p.score) AS avg_post_score,
        COALESCE(SUM(p.viewcount), 0) AS total_view_count,
        COALESCE(SUM(p.favoritecount), 0) AS total_favorite_count,
        COALESCE(SUM(p.answercount), 0) AS total_answer_count,
        COALESCE(SUM(p.commentcount), 0) AS total_post_comment_count
    FROM posts p
    GROUP BY p.owneruserid
),
user_comments AS (
    SELECT
        c.userid AS user_id,
        COUNT(c.id) AS comment_count,
        COALESCE(SUM(c.score), 0) AS total_comment_score,
        AVG(c.score) AS avg_comment_score
    FROM comments c
    GROUP BY c.userid
),
user_votes AS (
    SELECT
        v.userid AS user_id,
        COUNT(v.id) AS votes_cast,
        COUNT(CASE WHEN v.votetypeid = 1 THEN 1 END) AS upvote_cast,
        COUNT(CASE WHEN v.votetypeid = 2 THEN 1 END) AS downvote_cast,
        COALESCE(SUM(v.bountyamount), 0) AS total_bounty_given
    FROM votes v
    GROUP BY v.userid
),
user_badges AS (
    SELECT
        b.userid AS user_id,
        COUNT(b.id) AS badge_count
    FROM badges b
    GROUP BY b.userid
),
user_edits_last AS (
    SELECT
        p.lasteditoruserid AS user_id,
        COUNT(p.id) AS edit_count
    FROM posts p
    WHERE p.lasteditoruserid IS NOT NULL
    GROUP BY p.lasteditoruserid
),
user_posthistory AS (
    SELECT
        ph.userid AS user_id,
        COUNT(ph.id) AS posthistory_count,
        COUNT(CASE WHEN ph.posthistorytypeid = 2 THEN 1 END) AS edit_history_count
    FROM posthistory ph
    GROUP BY ph.userid
),
user_tags AS (
    SELECT
        p.owneruserid AS user_id,
        COUNT(t.id) AS tag_count
    FROM tags t
    JOIN posts p ON t.excerptpostid = p.id
    GROUP BY p.owneruserid
)
SELECT
    u.id AS user_id,
    u.reputation,
    u.creationdate,
    COALESCE(up.post_count, 0) AS post_count,
    COALESCE(up.total_post_score, 0) AS total_post_score,
    COALESCE(up.avg_post_score, 0) AS avg_post_score,
    COALESCE(up.total_view_count, 0) AS total_view_count,
    COALESCE(up.total_favorite_count, 0) AS total_favorite_count,
    COALESCE(up.total_answer_count, 0) AS total_answer_count,
    COALESCE(up.total_post_comment_count, 0) AS total_post_comment_count,
    COALESCE(uc.comment_count, 0) AS comment_count,
    COALESCE(uc.total_comment_score, 0) AS total_comment_score,
    COALESCE(uc.avg_comment_score, 0) AS avg_comment_score,
    COALESCE(uv.votes_cast, 0) AS votes_cast,
    COALESCE(uv.upvote_cast, 0) AS upvote_cast,
    COALESCE(uv.downvote_cast, 0) AS downvote_cast,
    COALESCE(uv.total_bounty_given, 0) AS total_bounty_given,
    COALESCE(ub.badge_count, 0) AS badge_count,
    COALESCE(ue.edit_count, 0) AS edit_count,
    COALESCE(uh.posthistory_count, 0) AS posthistory_count,
    COALESCE(uh.edit_history_count, 0) AS edit_history_count,
    COALESCE(ut.tag_count, 0) AS tag_count,
    (COALESCE(up.post_count, 0) +
     COALESCE(uc.comment_count, 0) +
     COALESCE(uv.votes_cast, 0) +
     COALESCE(ub.badge_count, 0) +
     COALESCE(ue.edit_count, 0) +
     COALESCE(uh.posthistory_count, 0) +
     COALESCE(ut.tag_count, 0)) AS total_activity
FROM users u
LEFT JOIN user_posts up ON up.user_id = u.id
LEFT JOIN user_comments uc ON uc.user_id = u.id
LEFT JOIN user_votes uv ON uv.user_id = u.id
LEFT JOIN user_badges ub ON ub.user_id = u.id
LEFT JOIN user_edits_last ue ON ue.user_id = u.id
LEFT JOIN user_posthistory uh ON uh.user_id = u.id
LEFT JOIN user_tags ut ON ut.user_id = u.id
ORDER BY u.reputation DESC
LIMIT 100

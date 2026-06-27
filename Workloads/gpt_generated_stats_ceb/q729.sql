WITH badge_counts AS (
    SELECT
        userid,
        COUNT(*) AS badge_count
    FROM badges
    GROUP BY userid
),
post_counts AS (
    SELECT
        owneruserid,
        COUNT(*) AS post_count,
        SUM(score) AS total_post_score,
        SUM(answercount) AS total_answer_count,
        SUM(commentcount) AS total_comment_count,
        SUM(favoritecount) AS total_favorite_count
    FROM posts
    GROUP BY owneruserid
),
comment_counts AS (
    SELECT
        userid,
        COUNT(*) AS comment_count
    FROM comments
    GROUP BY userid
),
vote_cast_counts AS (
    SELECT
        userid,
        COUNT(*) AS votes_cast_count,
        SUM(CASE WHEN votetypeid = 1 THEN 1 ELSE 0 END) AS upvote_cast_count,
        SUM(CASE WHEN votetypeid = 2 THEN 1 ELSE 0 END) AS downvote_cast_count
    FROM votes
    GROUP BY userid
),
vote_received_counts AS (
    SELECT
        p.owneruserid AS userid,
        COUNT(*) AS votes_received_count,
        SUM(CASE WHEN v.votetypeid = 1 THEN 1 ELSE 0 END) AS upvote_received_count,
        SUM(CASE WHEN v.votetypeid = 2 THEN 1 ELSE 0 END) AS downvote_received_count
    FROM votes v
    JOIN posts p ON v.postid = p.id
    GROUP BY p.owneruserid
),
user_info AS (
    SELECT
        id,
        reputation,
        creationdate,
        views,
        upvotes,
        downvotes
    FROM users
)
SELECT
    ui.id AS user_id,
    ui.reputation,
    ui.creationdate,
    ui.views,
    ui.upvotes,
    ui.downvotes,
    COALESCE(bc.badge_count, 0) AS badge_count,
    COALESCE(pc.post_count, 0) AS post_count,
    COALESCE(pc.total_post_score, 0) AS total_post_score,
    COALESCE(pc.total_answer_count, 0) AS total_answer_count,
    COALESCE(pc.total_comment_count, 0) AS total_comment_count,
    COALESCE(pc.total_favorite_count, 0) AS total_favorite_count,
    COALESCE(cc.comment_count, 0) AS comment_count,
    COALESCE(vc.votes_cast_count, 0) AS votes_cast_count,
    COALESCE(vc.upvote_cast_count, 0) AS upvote_cast_count,
    COALESCE(vc.downvote_cast_count, 0) AS downvote_cast_count,
    COALESCE(vr.votes_received_count, 0) AS votes_received_count,
    COALESCE(vr.upvote_received_count, 0) AS upvote_received_count,
    COALESCE(vr.downvote_received_count, 0) AS downvote_received_count
FROM user_info ui
LEFT JOIN badge_counts bc ON ui.id = bc.userid
LEFT JOIN post_counts pc ON ui.id = pc.owneruserid
LEFT JOIN comment_counts cc ON ui.id = cc.userid
LEFT JOIN vote_cast_counts vc ON ui.id = vc.userid
LEFT JOIN vote_received_counts vr ON ui.id = vr.userid
ORDER BY ui.reputation DESC
LIMIT 100

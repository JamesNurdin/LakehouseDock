WITH user_info AS (
    SELECT
        u.id AS user_id,
        u.reputation,
        u.creationdate,
        u.views,
        u.upvotes,
        u.downvotes
    FROM users u
),
post_owner_agg AS (
    SELECT
        p.owneruserid AS user_id,
        COUNT(*) AS post_count,
        SUM(p.score) AS post_score_sum,
        AVG(p.score) AS post_score_avg,
        SUM(p.viewcount) AS post_viewcount_sum,
        SUM(p.answercount) AS post_answercount_sum,
        SUM(p.favoritecount) AS post_favoritecount_sum
    FROM posts p
    GROUP BY p.owneruserid
),
post_editor_agg AS (
    SELECT
        p.lasteditoruserid AS user_id,
        COUNT(*) AS edited_post_count
    FROM posts p
    WHERE p.lasteditoruserid IS NOT NULL
    GROUP BY p.lasteditoruserid
),
comment_agg AS (
    SELECT
        c.userid AS user_id,
        COUNT(*) AS comment_count,
        SUM(c.score) AS comment_score_sum,
        AVG(c.score) AS comment_score_avg
    FROM comments c
    GROUP BY c.userid
),
vote_cast_agg AS (
    SELECT
        v.userid AS user_id,
        COUNT(*) AS votes_cast_count,
        SUM(CASE WHEN v.votetypeid = 2 THEN 1 ELSE 0 END) AS upvote_cast_count,
        SUM(CASE WHEN v.votetypeid = 3 THEN 1 ELSE 0 END) AS downvote_cast_count
    FROM votes v
    GROUP BY v.userid
),
vote_received_agg AS (
    SELECT
        p.owneruserid AS user_id,
        COUNT(*) AS votes_received_count,
        SUM(CASE WHEN v.votetypeid = 2 THEN 1 ELSE 0 END) AS upvote_received_count,
        SUM(CASE WHEN v.votetypeid = 3 THEN 1 ELSE 0 END) AS downvote_received_count
    FROM votes v
    JOIN posts p ON v.postid = p.id
    GROUP BY p.owneruserid
),
badge_agg AS (
    SELECT
        b.userid AS user_id,
        COUNT(*) AS badge_count
    FROM badges b
    GROUP BY b.userid
),
posthistory_agg AS (
    SELECT
        ph.userid AS user_id,
        COUNT(*) AS posthistory_count
    FROM posthistory ph
    GROUP BY ph.userid
)
SELECT
    u.user_id,
    u.reputation,
    u.creationdate,
    u.views,
    u.upvotes,
    u.downvotes,
    COALESCE(po.post_count, 0) AS post_count,
    COALESCE(po.post_score_sum, 0) AS post_score_sum,
    COALESCE(po.post_score_avg, 0) AS post_score_avg,
    COALESCE(po.post_viewcount_sum, 0) AS post_viewcount_sum,
    COALESCE(po.post_answercount_sum, 0) AS post_answercount_sum,
    COALESCE(po.post_favoritecount_sum, 0) AS post_favoritecount_sum,
    COALESCE(pe.edited_post_count, 0) AS edited_post_count,
    COALESCE(ca.comment_count, 0) AS comment_count,
    COALESCE(ca.comment_score_sum, 0) AS comment_score_sum,
    COALESCE(ca.comment_score_avg, 0) AS comment_score_avg,
    COALESCE(vc.votes_cast_count, 0) AS votes_cast_count,
    COALESCE(vc.upvote_cast_count, 0) AS upvote_cast_count,
    COALESCE(vc.downvote_cast_count, 0) AS downvote_cast_count,
    COALESCE(vr.votes_received_count, 0) AS votes_received_count,
    COALESCE(vr.upvote_received_count, 0) AS upvote_received_count,
    COALESCE(vr.downvote_received_count, 0) AS downvote_received_count,
    COALESCE(b.badge_count, 0) AS badge_count,
    COALESCE(ph.posthistory_count, 0) AS posthistory_count
FROM user_info u
LEFT JOIN post_owner_agg po ON po.user_id = u.user_id
LEFT JOIN post_editor_agg pe ON pe.user_id = u.user_id
LEFT JOIN comment_agg ca ON ca.user_id = u.user_id
LEFT JOIN vote_cast_agg vc ON vc.user_id = u.user_id
LEFT JOIN vote_received_agg vr ON vr.user_id = u.user_id
LEFT JOIN badge_agg b ON b.user_id = u.user_id
LEFT JOIN posthistory_agg ph ON ph.user_id = u.user_id
ORDER BY u.reputation DESC
LIMIT 100

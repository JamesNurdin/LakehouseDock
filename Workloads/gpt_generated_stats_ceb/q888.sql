WITH
    user_base AS (
        SELECT u.id,
               u.reputation,
               u.creationdate,
               u.views,
               u.upvotes,
               u.downvotes
        FROM users u
    ),
    badge_counts AS (
        SELECT b.userid AS user_id,
               COUNT(*) AS badge_count
        FROM badges b
        GROUP BY b.userid
    ),
    post_metrics AS (
        SELECT p.owneruserid AS user_id,
               COUNT(*) AS post_count,
               SUM(p.score) AS post_score_sum,
               SUM(p.viewcount) AS post_view_sum,
               SUM(p.answercount) AS post_answer_sum,
               SUM(p.commentcount) AS post_comment_sum,
               SUM(p.favoritecount) AS post_favorite_sum
        FROM posts p
        GROUP BY p.owneruserid
    ),
    comment_metrics AS (
        SELECT c.userid AS user_id,
               COUNT(*) AS comment_count,
               SUM(c.score) AS comment_score_sum
        FROM comments c
        GROUP BY c.userid
    ),
    vote_cast_metrics AS (
        SELECT v.userid AS user_id,
               COUNT(*) AS votes_cast,
               SUM(v.bountyamount) AS bounty_cast_sum
        FROM votes v
        GROUP BY v.userid
    ),
    vote_received_metrics AS (
        SELECT p.owneruserid AS user_id,
               COUNT(v.id) AS votes_received,
               SUM(v.bountyamount) AS bounty_received_sum
        FROM posts p
        LEFT JOIN votes v ON v.postid = p.id
        GROUP BY p.owneruserid
    ),
    tag_counts AS (
        SELECT p.owneruserid AS user_id,
               COUNT(DISTINCT t.id) AS tag_count
        FROM posts p
        LEFT JOIN tags t ON t.excerptpostid = p.id
        GROUP BY p.owneruserid
    ),
    posthistory_counts AS (
        SELECT ph.userid AS user_id,
               COUNT(*) AS posthistory_count,
               COUNT(DISTINCT ph.posthistorytypeid) AS distinct_history_type_count
        FROM posthistory ph
        GROUP BY ph.userid
    ),
    postlink_counts AS (
        SELECT p.owneruserid AS user_id,
               COUNT(pl.id) AS postlink_count
        FROM postlinks pl
        JOIN posts p ON pl.postid = p.id
        GROUP BY p.owneruserid
    )
SELECT ub.id,
       ub.reputation,
       ub.creationdate,
       ub.views,
       ub.upvotes,
       ub.downvotes,
       COALESCE(bc.badge_count, 0) AS badge_count,
       COALESCE(pm.post_count, 0) AS post_count,
       COALESCE(pm.post_score_sum, 0) AS post_score_sum,
       COALESCE(pm.post_view_sum, 0) AS post_view_sum,
       COALESCE(pm.post_answer_sum, 0) AS post_answer_sum,
       COALESCE(pm.post_comment_sum, 0) AS post_comment_sum,
       COALESCE(pm.post_favorite_sum, 0) AS post_favorite_sum,
       COALESCE(cm.comment_count, 0) AS comment_count,
       COALESCE(cm.comment_score_sum, 0) AS comment_score_sum,
       COALESCE(vc.votes_cast, 0) AS votes_cast,
       COALESCE(vc.bounty_cast_sum, 0) AS bounty_cast_sum,
       COALESCE(vr.votes_received, 0) AS votes_received,
       COALESCE(vr.bounty_received_sum, 0) AS bounty_received_sum,
       COALESCE(tc.tag_count, 0) AS tag_count,
       COALESCE(phc.posthistory_count, 0) AS posthistory_count,
       COALESCE(phc.distinct_history_type_count, 0) AS distinct_history_type_count,
       COALESCE(plc.postlink_count, 0) AS postlink_count
FROM user_base ub
LEFT JOIN badge_counts bc ON bc.user_id = ub.id
LEFT JOIN post_metrics pm ON pm.user_id = ub.id
LEFT JOIN comment_metrics cm ON cm.user_id = ub.id
LEFT JOIN vote_cast_metrics vc ON vc.user_id = ub.id
LEFT JOIN vote_received_metrics vr ON vr.user_id = ub.id
LEFT JOIN tag_counts tc ON tc.user_id = ub.id
LEFT JOIN posthistory_counts phc ON phc.user_id = ub.id
LEFT JOIN postlink_counts plc ON plc.user_id = ub.id
ORDER BY ub.reputation DESC
LIMIT 100

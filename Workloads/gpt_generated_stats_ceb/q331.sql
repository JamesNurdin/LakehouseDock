WITH
    badge_counts AS (
        SELECT userid,
               count(*) AS badge_count
        FROM badges
        GROUP BY userid
    ),
    post_metrics AS (
        SELECT owneruserid AS userid,
               count(*) AS post_count,
               sum(score) AS post_score_sum,
               sum(viewcount) AS post_view_sum,
               sum(answercount) AS answer_count,
               sum(commentcount) AS post_comment_count,
               sum(favoritecount) AS favorite_count
        FROM posts
        GROUP BY owneruserid
    ),
    comment_metrics AS (
        SELECT userid,
               count(*) AS comment_made_count,
               sum(score) AS comment_score_sum
        FROM comments
        GROUP BY userid
    ),
    votes_cast AS (
        SELECT userid,
               count(*) AS votes_cast_count,
               sum(CASE WHEN votetypeid = 1 THEN 1 ELSE 0 END) AS upvote_cast,
               sum(CASE WHEN votetypeid = 2 THEN 1 ELSE 0 END) AS downvote_cast
        FROM votes
        GROUP BY userid
    ),
    votes_received AS (
        SELECT p.owneruserid AS userid,
               count(v.id) AS votes_received_count,
               sum(CASE WHEN v.votetypeid = 1 THEN 1 ELSE 0 END) AS upvote_received,
               sum(CASE WHEN v.votetypeid = 2 THEN 1 ELSE 0 END) AS downvote_received
        FROM votes v
        JOIN posts p ON v.postid = p.id
        GROUP BY p.owneruserid
    ),
    posthistory_counts AS (
        SELECT userid,
               count(*) AS posthistory_count
        FROM posthistory
        GROUP BY userid
    ),
    postlinks_counts AS (
        SELECT p.owneruserid AS userid,
               count(pl.id) AS postlinks_count
        FROM postlinks pl
        JOIN posts p ON pl.postid = p.id
        GROUP BY p.owneruserid
    ),
    tag_counts AS (
        SELECT p.owneruserid AS userid,
               count(DISTINCT t.id) AS distinct_tag_count
        FROM tags t
        JOIN posts p ON t.excerptpostid = p.id
        GROUP BY p.owneruserid
    )
SELECT
    u.id AS user_id,
    u.reputation,
    u.creationdate,
    u.views,
    u.upvotes,
    u.downvotes,
    COALESCE(bc.badge_count, 0) AS badge_count,
    COALESCE(pm.post_count, 0) AS post_count,
    COALESCE(pm.post_score_sum, 0) AS post_score_sum,
    COALESCE(pm.post_view_sum, 0) AS post_view_sum,
    COALESCE(pm.answer_count, 0) AS answer_count,
    COALESCE(pm.post_comment_count, 0) AS post_comment_count,
    COALESCE(pm.favorite_count, 0) AS favorite_count,
    COALESCE(cm.comment_made_count, 0) AS comment_made_count,
    COALESCE(cm.comment_score_sum, 0) AS comment_score_sum,
    COALESCE(vc.votes_cast_count, 0) AS votes_cast_count,
    COALESCE(vc.upvote_cast, 0) AS upvote_cast,
    COALESCE(vc.downvote_cast, 0) AS downvote_cast,
    COALESCE(vr.votes_received_count, 0) AS votes_received_count,
    COALESCE(vr.upvote_received, 0) AS upvote_received,
    COALESCE(vr.downvote_received, 0) AS downvote_received,
    COALESCE(phc.posthistory_count, 0) AS posthistory_count,
    COALESCE(plc.postlinks_count, 0) AS postlinks_count,
    COALESCE(tc.distinct_tag_count, 0) AS distinct_tag_count
FROM users u
LEFT JOIN badge_counts bc      ON bc.userid = u.id
LEFT JOIN post_metrics pm      ON pm.userid = u.id
LEFT JOIN comment_metrics cm   ON cm.userid = u.id
LEFT JOIN votes_cast vc        ON vc.userid = u.id
LEFT JOIN votes_received vr    ON vr.userid = u.id
LEFT JOIN posthistory_counts phc ON phc.userid = u.id
LEFT JOIN postlinks_counts plc ON plc.userid = u.id
LEFT JOIN tag_counts tc        ON tc.userid = u.id
ORDER BY u.reputation DESC
LIMIT 100

WITH
    user_info AS (
        SELECT id,
               reputation,
               creationdate,
               views,
               upvotes,
               downvotes
        FROM users
    ),
    badge_counts AS (
        SELECT userid,
               COUNT(*) AS badge_count
        FROM badges
        GROUP BY userid
    ),
    post_metrics AS (
        SELECT owneruserid,
               COUNT(*) AS total_posts,
               COUNT(*) FILTER (WHERE posttypeid = 1) AS question_count,
               COUNT(*) FILTER (WHERE posttypeid = 2) AS answer_count,
               SUM(viewcount) AS total_views,
               AVG(score) AS avg_post_score
        FROM posts
        GROUP BY owneruserid
    ),
    comment_counts AS (
        SELECT userid,
               COUNT(*) AS comment_count
        FROM comments
        GROUP BY userid
    ),
    votes_given AS (
        SELECT userid,
               SUM(CASE WHEN votetypeid = 2 THEN 1 ELSE 0 END) AS upvotes_given,
               SUM(CASE WHEN votetypeid = 3 THEN 1 ELSE 0 END) AS downvotes_given
        FROM votes
        GROUP BY userid
    ),
    votes_received AS (
        SELECT p.owneruserid,
               SUM(CASE WHEN v.votetypeid = 2 THEN 1 ELSE 0 END) AS upvotes_received,
               SUM(CASE WHEN v.votetypeid = 3 THEN 1 ELSE 0 END) AS downvotes_received
        FROM votes v
        JOIN posts p ON v.postid = p.id
        GROUP BY p.owneruserid
    ),
    bounty_received AS (
        SELECT p.owneruserid,
               SUM(v.bountyamount) AS total_bounty_received
        FROM votes v
        JOIN posts p ON v.postid = p.id
        WHERE v.bountyamount > 0
        GROUP BY p.owneruserid
    )
SELECT
    ui.id AS user_id,
    ui.reputation,
    ui.creationdate,
    ui.views,
    ui.upvotes,
    ui.downvotes,
    COALESCE(bc.badge_count, 0) AS badge_count,
    COALESCE(pm.total_posts, 0) AS total_posts,
    COALESCE(pm.question_count, 0) AS question_count,
    COALESCE(pm.answer_count, 0) AS answer_count,
    COALESCE(pm.total_views, 0) AS total_views,
    COALESCE(pm.avg_post_score, 0) AS avg_post_score,
    COALESCE(cc.comment_count, 0) AS comment_count,
    COALESCE(vg.upvotes_given, 0) AS upvotes_given,
    COALESCE(vg.downvotes_given, 0) AS downvotes_given,
    COALESCE(vr.upvotes_received, 0) AS upvotes_received,
    COALESCE(vr.downvotes_received, 0) AS downvotes_received,
    COALESCE(br.total_bounty_received, 0) AS total_bounty_received
FROM user_info ui
LEFT JOIN badge_counts bc ON bc.userid = ui.id
LEFT JOIN post_metrics pm ON pm.owneruserid = ui.id
LEFT JOIN comment_counts cc ON cc.userid = ui.id
LEFT JOIN votes_given vg ON vg.userid = ui.id
LEFT JOIN votes_received vr ON vr.owneruserid = ui.id
LEFT JOIN bounty_received br ON br.owneruserid = ui.id
ORDER BY ui.reputation DESC, badge_count DESC
LIMIT 50

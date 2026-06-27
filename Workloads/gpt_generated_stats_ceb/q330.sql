WITH
    owner_agg AS (
        SELECT
            p.owneruserid AS user_id,
            COUNT(*) AS posts_owned,
            SUM(p.score) AS total_score_owned,
            SUM(p.viewcount) AS total_views_owned,
            SUM(p.answercount) AS total_answers_owned,
            SUM(p.commentcount) AS total_comments_owned,
            SUM(p.favoritecount) AS total_favorites_owned
        FROM posts p
        GROUP BY p.owneruserid
    ),
    editor_agg AS (
        SELECT
            p.lasteditoruserid AS user_id,
            COUNT(*) AS posts_edited
        FROM posts p
        GROUP BY p.lasteditoruserid
    ),
    votes_cast_agg AS (
        SELECT
            v.userid AS user_id,
            COUNT(*) AS votes_cast,
            SUM(CASE WHEN v.votetypeid = 2 THEN 1 ELSE 0 END) AS upvotes_cast,
            SUM(CASE WHEN v.votetypeid = 3 THEN 1 ELSE 0 END) AS downvotes_cast,
            SUM(v.bountyamount) AS total_bounty_cast
        FROM votes v
        GROUP BY v.userid
    ),
    votes_received_agg AS (
        SELECT
            p.owneruserid AS user_id,
            COUNT(v.id) AS votes_received,
            SUM(CASE WHEN v.votetypeid = 2 THEN 1 ELSE 0 END) AS upvotes_received,
            SUM(CASE WHEN v.votetypeid = 3 THEN 1 ELSE 0 END) AS downvotes_received,
            SUM(v.bountyamount) AS total_bounty_received
        FROM posts p
        LEFT JOIN votes v ON v.postid = p.id
        GROUP BY p.owneruserid
    )
SELECT
    u.id AS user_id,
    u.reputation,
    u.creationdate,
    u.views,
    u.upvotes,
    u.downvotes,
    COALESCE(o.posts_owned, 0) AS posts_owned,
    COALESCE(o.total_score_owned, 0) AS total_score_owned,
    COALESCE(o.total_views_owned, 0) AS total_views_owned,
    COALESCE(o.total_answers_owned, 0) AS total_answers_owned,
    COALESCE(o.total_comments_owned, 0) AS total_comments_owned,
    COALESCE(o.total_favorites_owned, 0) AS total_favorites_owned,
    COALESCE(e.posts_edited, 0) AS posts_edited,
    COALESCE(vc.votes_cast, 0) AS votes_cast,
    COALESCE(vc.upvotes_cast, 0) AS upvotes_cast,
    COALESCE(vc.downvotes_cast, 0) AS downvotes_cast,
    COALESCE(vc.total_bounty_cast, 0) AS total_bounty_cast,
    COALESCE(vr.votes_received, 0) AS votes_received,
    COALESCE(vr.upvotes_received, 0) AS upvotes_received,
    COALESCE(vr.downvotes_received, 0) AS downvotes_received,
    COALESCE(vr.total_bounty_received, 0) AS total_bounty_received,
    CASE WHEN vr.votes_received > 0 THEN CAST(vc.votes_cast AS double) / vr.votes_received ELSE NULL END AS vote_engagement_ratio
FROM users u
LEFT JOIN owner_agg o ON o.user_id = u.id
LEFT JOIN editor_agg e ON e.user_id = u.id
LEFT JOIN votes_cast_agg vc ON vc.user_id = u.id
LEFT JOIN votes_received_agg vr ON vr.user_id = u.id
ORDER BY u.reputation DESC
LIMIT 100

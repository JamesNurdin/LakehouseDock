WITH
    badge_counts AS (
        SELECT u.id AS user_id,
               COUNT(b.id) AS badge_count
        FROM users u
        LEFT JOIN badges b ON b.userid = u.id
        GROUP BY u.id
    ),
    post_metrics AS (
        SELECT u.id AS user_id,
               COUNT(p.id) AS post_count,
               COALESCE(SUM(p.score), 0) AS post_score_sum,
               COALESCE(SUM(p.viewcount), 0) AS post_view_sum
        FROM users u
        LEFT JOIN posts p ON p.owneruserid = u.id
        GROUP BY u.id
    ),
    edit_counts AS (
        SELECT u.id AS user_id,
               COUNT(p.id) AS edit_count
        FROM users u
        LEFT JOIN posts p ON p.lasteditoruserid = u.id
        GROUP BY u.id
    ),
    comment_metrics AS (
        SELECT u.id AS user_id,
               COUNT(c.id) AS comment_count,
               COALESCE(SUM(c.score), 0) AS comment_score_sum
        FROM users u
        LEFT JOIN comments c ON c.userid = u.id
        GROUP BY u.id
    ),
    votes_cast AS (
        SELECT u.id AS user_id,
               COUNT(v.id) AS votes_cast,
               COALESCE(SUM(v.bountyamount), 0) AS bounty_amount_sum
        FROM users u
        LEFT JOIN votes v ON v.userid = u.id
        GROUP BY u.id
    ),
    votes_received AS (
        SELECT u.id AS user_id,
               COUNT(v.id) AS votes_received,
               COALESCE(SUM(CASE WHEN v.votetypeid = 1 THEN 1 ELSE 0 END), 0) AS upvotes_received,
               COALESCE(SUM(CASE WHEN v.votetypeid = 2 THEN 1 ELSE 0 END), 0) AS downvotes_received
        FROM users u
        LEFT JOIN posts p ON p.owneruserid = u.id
        LEFT JOIN votes v ON v.postid = p.id
        GROUP BY u.id
    ),
    tag_counts AS (
        SELECT u.id AS user_id,
               COUNT(DISTINCT t.id) AS distinct_tag_count
        FROM users u
        LEFT JOIN posts p ON p.owneruserid = u.id
        LEFT JOIN tags t ON t.excerptpostid = p.id
        GROUP BY u.id
    )
SELECT
    u.id,
    u.reputation,
    bc.badge_count,
    pm.post_count,
    pm.post_score_sum,
    pm.post_view_sum,
    ec.edit_count,
    cm.comment_count,
    cm.comment_score_sum,
    vc.votes_cast,
    vc.bounty_amount_sum,
    vr.votes_received,
    vr.upvotes_received,
    vr.downvotes_received,
    tc.distinct_tag_count
FROM users u
LEFT JOIN badge_counts bc ON bc.user_id = u.id
LEFT JOIN post_metrics pm ON pm.user_id = u.id
LEFT JOIN edit_counts ec ON ec.user_id = u.id
LEFT JOIN comment_metrics cm ON cm.user_id = u.id
LEFT JOIN votes_cast vc ON vc.user_id = u.id
LEFT JOIN votes_received vr ON vr.user_id = u.id
LEFT JOIN tag_counts tc ON tc.user_id = u.id
ORDER BY u.reputation DESC
LIMIT 100

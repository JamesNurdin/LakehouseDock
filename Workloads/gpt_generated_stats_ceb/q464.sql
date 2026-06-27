WITH user_posts AS (
    SELECT owneruserid AS user_id,
           COUNT(*) AS total_posts_owned,
           SUM(score) AS total_post_score,
           AVG(score) AS average_post_score
    FROM posts
    GROUP BY owneruserid
),
user_posts_edited AS (
    SELECT lasteditoruserid AS user_id,
           COUNT(*) AS total_posts_edited
    FROM posts
    GROUP BY lasteditoruserid
),
user_comments_made AS (
    SELECT userid AS user_id,
           COUNT(*) AS total_comments_made
    FROM comments
    GROUP BY userid
),
user_votes_cast AS (
    SELECT userid AS user_id,
           COUNT(*) AS total_votes_cast,
           COALESCE(SUM(bountyamount), 0) AS total_bounty_cast
    FROM votes
    GROUP BY userid
),
user_votes_received AS (
    SELECT p.owneruserid AS user_id,
           COUNT(*) AS total_votes_received,
           COALESCE(SUM(v.bountyamount), 0) AS total_bounty_received
    FROM votes v
    JOIN posts p ON v.postid = p.id
    GROUP BY p.owneruserid
),
user_comments_received AS (
    SELECT p.owneruserid AS user_id,
           COUNT(*) AS total_comments_received
    FROM comments c
    JOIN posts p ON c.postid = p.id
    GROUP BY p.owneruserid
),
user_posthistory_contrib AS (
    SELECT userid AS user_id,
           COUNT(*) AS total_post_history_contributions
    FROM posthistory
    GROUP BY userid
),
user_posthistory_by_typeid AS (
    SELECT p.owneruserid AS user_id,
           COUNT(*) AS total_post_history_by_typeid
    FROM posthistory ph
    JOIN posts p ON ph.posthistorytypeid = p.id
    GROUP BY p.owneruserid
),
user_tags_excerpt AS (
    SELECT p.owneruserid AS user_id,
           COUNT(DISTINCT t.id) AS total_tags_excerpt
    FROM tags t
    JOIN posts p ON t.excerptpostid = p.id
    GROUP BY p.owneruserid
)
SELECT u.id AS user_id,
       u.reputation,
       COALESCE(up.total_posts_owned, 0) AS total_posts_owned,
       COALESCE(up.total_post_score, 0) AS total_post_score,
       COALESCE(up.average_post_score, 0) AS average_post_score,
       COALESCE(ue.total_posts_edited, 0) AS total_posts_edited,
       COALESCE(cm.total_comments_made, 0) AS total_comments_made,
       COALESCE(cr.total_comments_received, 0) AS total_comments_received,
       COALESCE(vc.total_votes_cast, 0) AS total_votes_cast,
       COALESCE(vc.total_bounty_cast, 0) AS total_bounty_cast,
       COALESCE(vr.total_votes_received, 0) AS total_votes_received,
       COALESCE(vr.total_bounty_received, 0) AS total_bounty_received,
       COALESCE(ph.total_post_history_contributions, 0) AS total_post_history_contributions,
       COALESCE(pht.total_post_history_by_typeid, 0) AS total_post_history_by_typeid,
       COALESCE(tg.total_tags_excerpt, 0) AS total_tags_excerpt
FROM users u
LEFT JOIN user_posts up ON u.id = up.user_id
LEFT JOIN user_posts_edited ue ON u.id = ue.user_id
LEFT JOIN user_comments_made cm ON u.id = cm.user_id
LEFT JOIN user_comments_received cr ON u.id = cr.user_id
LEFT JOIN user_votes_cast vc ON u.id = vc.user_id
LEFT JOIN user_votes_received vr ON u.id = vr.user_id
LEFT JOIN user_posthistory_contrib ph ON u.id = ph.user_id
LEFT JOIN user_posthistory_by_typeid pht ON u.id = pht.user_id
LEFT JOIN user_tags_excerpt tg ON u.id = tg.user_id
ORDER BY total_posts_owned DESC
LIMIT 100

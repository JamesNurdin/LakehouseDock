WITH user_posts AS (
    SELECT u.id,
           COUNT(p.id) AS post_count,
           COALESCE(SUM(p.score), 0) AS post_score_sum,
           COALESCE(AVG(p.score), 0) AS post_score_avg,
           COALESCE(SUM(p.viewcount), 0) AS post_viewcount_sum,
           COALESCE(SUM(p.favoritecount), 0) AS post_favoritecount_sum
    FROM users u
    LEFT JOIN posts p
        ON p.owneruserid = u.id
    GROUP BY u.id
),
user_comments_made AS (
    SELECT u.id,
           COUNT(c.id) AS comment_made_count
    FROM users u
    LEFT JOIN comments c
        ON c.userid = u.id
    GROUP BY u.id
),
user_comments_received AS (
    SELECT u.id,
           COUNT(c.id) AS comment_received_count
    FROM users u
    LEFT JOIN posts p
        ON p.owneruserid = u.id
    LEFT JOIN comments c
        ON c.postid = p.id
    GROUP BY u.id
),
user_votes_cast AS (
    SELECT u.id,
           COUNT(v.id) AS votes_cast_count,
           SUM(CASE WHEN v.votetypeid = 2 THEN 1 ELSE 0 END) AS upvotes_cast,
           SUM(CASE WHEN v.votetypeid = 3 THEN 1 ELSE 0 END) AS downvotes_cast
    FROM users u
    LEFT JOIN votes v
        ON v.userid = u.id
    GROUP BY u.id
),
user_votes_received AS (
    SELECT u.id,
           COUNT(v.id) AS votes_received_count,
           SUM(CASE WHEN v.votetypeid = 2 THEN 1 ELSE 0 END) AS upvotes_received,
           SUM(CASE WHEN v.votetypeid = 3 THEN 1 ELSE 0 END) AS downvotes_received
    FROM users u
    LEFT JOIN posts p
        ON p.owneruserid = u.id
    LEFT JOIN votes v
        ON v.postid = p.id
    GROUP BY u.id
),
user_badges AS (
    SELECT u.id,
           COUNT(b.id) AS badge_count
    FROM users u
    LEFT JOIN badges b
        ON b.userid = u.id
    GROUP BY u.id
),
user_posthistory AS (
    SELECT u.id,
           COUNT(ph.id) AS posthistory_count
    FROM users u
    LEFT JOIN posthistory ph
        ON ph.userid = u.id
    GROUP BY u.id
),
user_postlinks_created AS (
    SELECT u.id,
           COUNT(pl.id) AS postlinks_created_count
    FROM users u
    LEFT JOIN posts p
        ON p.owneruserid = u.id
    LEFT JOIN postlinks pl
        ON pl.postid = p.id
    GROUP BY u.id
),
user_postlinks_targeted AS (
    SELECT u.id,
           COUNT(pl.id) AS postlinks_targeted_count
    FROM users u
    LEFT JOIN posts p
        ON p.owneruserid = u.id
    LEFT JOIN postlinks pl
        ON pl.relatedpostid = p.id
    GROUP BY u.id
),
user_tags_used AS (
    SELECT u.id,
           COUNT(DISTINCT t.id) AS distinct_tag_count
    FROM users u
    LEFT JOIN posts p
        ON p.owneruserid = u.id
    LEFT JOIN tags t
        ON t.excerptpostid = p.id
    GROUP BY u.id
)
SELECT u.id,
       u.reputation,
       up.post_count,
       up.post_score_sum,
       up.post_score_avg,
       up.post_viewcount_sum,
       up.post_favoritecount_sum,
       cm.comment_made_count,
       cr.comment_received_count,
       vc.votes_cast_count,
       vc.upvotes_cast,
       vc.downvotes_cast,
       vr.votes_received_count,
       vr.upvotes_received,
       vr.downvotes_received,
       b.badge_count,
       ph.posthistory_count,
       plc.postlinks_created_count,
       plt.postlinks_targeted_count,
       tg.distinct_tag_count
FROM users u
LEFT JOIN user_posts up ON up.id = u.id
LEFT JOIN user_comments_made cm ON cm.id = u.id
LEFT JOIN user_comments_received cr ON cr.id = u.id
LEFT JOIN user_votes_cast vc ON vc.id = u.id
LEFT JOIN user_votes_received vr ON vr.id = u.id
LEFT JOIN user_badges b ON b.id = u.id
LEFT JOIN user_posthistory ph ON ph.id = u.id
LEFT JOIN user_postlinks_created plc ON plc.id = u.id
LEFT JOIN user_postlinks_targeted plt ON plt.id = u.id
LEFT JOIN user_tags_used tg ON tg.id = u.id
ORDER BY up.post_score_sum DESC
LIMIT 100

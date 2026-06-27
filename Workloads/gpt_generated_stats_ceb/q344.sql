WITH user_badges AS (
    SELECT u.id AS user_id,
           COUNT(b.id) AS badge_count
    FROM users u
    LEFT JOIN badges b ON b.userid = u.id
    GROUP BY u.id
),
user_posts AS (
    SELECT u.id AS user_id,
           COUNT(p.id) AS post_count,
           SUM(p.score) AS total_post_score,
           SUM(p.viewcount) AS total_views,
           SUM(CASE WHEN p.posttypeid = 2 THEN 1 ELSE 0 END) AS answer_post_count
    FROM users u
    LEFT JOIN posts p ON p.owneruserid = u.id
    GROUP BY u.id
),
user_comments AS (
    SELECT u.id AS user_id,
           COUNT(c.id) AS comment_count,
           SUM(c.score) AS comment_score_sum
    FROM users u
    LEFT JOIN comments c ON c.userid = u.id
    GROUP BY u.id
),
user_votes_cast AS (
    SELECT u.id AS user_id,
           COUNT(v.id) AS votes_cast,
           SUM(CASE WHEN v.votetypeid = 1 THEN 1 ELSE 0 END) AS upvote_cast,
           SUM(CASE WHEN v.votetypeid = 2 THEN 1 ELSE 0 END) AS downvote_cast
    FROM users u
    LEFT JOIN votes v ON v.userid = u.id
    GROUP BY u.id
),
user_votes_received AS (
    SELECT u.id AS user_id,
           COUNT(v.id) AS votes_received,
           SUM(CASE WHEN v.votetypeid = 1 THEN 1 ELSE 0 END) AS upvotes_received,
           SUM(CASE WHEN v.votetypeid = 2 THEN 1 ELSE 0 END) AS downvotes_received
    FROM users u
    LEFT JOIN posts p ON p.owneruserid = u.id
    LEFT JOIN votes v ON v.postid = p.id
    GROUP BY u.id
),
user_tags AS (
    SELECT u.id AS user_id,
           COUNT(DISTINCT t.id) AS tag_count
    FROM users u
    LEFT JOIN posts p ON p.owneruserid = u.id
    LEFT JOIN tags t ON t.excerptpostid = p.id
    GROUP BY u.id
)
SELECT
    u.id,
    u.reputation,
    COALESCE(ub.badge_count, 0)        AS badge_count,
    COALESCE(up.post_count, 0)         AS post_count,
    COALESCE(up.answer_post_count, 0)  AS answer_post_count,
    COALESCE(up.total_post_score, 0)   AS total_post_score,
    COALESCE(up.total_views, 0)        AS total_views,
    COALESCE(uc.comment_count, 0)      AS comment_count,
    COALESCE(uc.comment_score_sum, 0)  AS comment_score_sum,
    COALESCE(vc.votes_cast, 0)         AS votes_cast,
    COALESCE(vc.upvote_cast, 0)        AS upvote_cast,
    COALESCE(vc.downvote_cast, 0)      AS downvote_cast,
    COALESCE(vr.votes_received, 0)     AS votes_received,
    COALESCE(vr.upvotes_received, 0)   AS upvotes_received,
    COALESCE(vr.downvotes_received, 0) AS downvotes_received,
    COALESCE(ut.tag_count, 0)          AS tag_count
FROM users u
LEFT JOIN user_badges      ub ON ub.user_id = u.id
LEFT JOIN user_posts       up ON up.user_id = u.id
LEFT JOIN user_comments    uc ON uc.user_id = u.id
LEFT JOIN user_votes_cast  vc ON vc.user_id = u.id
LEFT JOIN user_votes_received vr ON vr.user_id = u.id
LEFT JOIN user_tags        ut ON ut.user_id = u.id
ORDER BY badge_count DESC, u.reputation DESC

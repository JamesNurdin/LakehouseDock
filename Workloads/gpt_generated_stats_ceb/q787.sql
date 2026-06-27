WITH badge_counts AS (
    SELECT userid AS user_id,
           COUNT(*) AS badge_count
    FROM badges
    GROUP BY userid
),
question_counts AS (
    SELECT owneruserid AS user_id,
           COUNT(*) AS question_count
    FROM posts
    WHERE posttypeid = 1
    GROUP BY owneruserid
),
answer_counts AS (
    SELECT owneruserid AS user_id,
           COUNT(*) AS answer_count
    FROM posts
    WHERE posttypeid = 2
    GROUP BY owneruserid
),
post_avg_score AS (
    SELECT owneruserid AS user_id,
           AVG(score) AS avg_post_score
    FROM posts
    GROUP BY owneruserid
),
comment_counts AS (
    SELECT userid AS user_id,
           COUNT(*) AS comment_count
    FROM comments
    GROUP BY userid
),
received_votes AS (
    SELECT p.owneruserid AS user_id,
           COUNT(v.id) AS received_vote_count,
           COALESCE(SUM(v.bountyamount), 0) AS total_bounty_received
    FROM posts p
    JOIN votes v ON v.postid = p.id
    GROUP BY p.owneruserid
),
tag_counts AS (
    SELECT p.owneruserid AS user_id,
           COUNT(DISTINCT t.id) AS tag_count
    FROM posts p
    JOIN tags t ON t.excerptpostid = p.id
    GROUP BY p.owneruserid
),
postlink_counts AS (
    SELECT p.owneruserid AS user_id,
           COUNT(pl.id) AS postlink_count
    FROM posts p
    JOIN postlinks pl ON pl.postid = p.id
    GROUP BY p.owneruserid
)
SELECT
    u.id AS user_id,
    u.reputation,
    COALESCE(bc.badge_count, 0) AS badge_count,
    COALESCE(qc.question_count, 0) AS question_count,
    COALESCE(ac.answer_count, 0) AS answer_count,
    COALESCE(pas.avg_post_score, 0) AS avg_post_score,
    COALESCE(cc.comment_count, 0) AS comment_count,
    COALESCE(rv.received_vote_count, 0) AS received_vote_count,
    COALESCE(rv.total_bounty_received, 0) AS total_bounty_received,
    COALESCE(tc.tag_count, 0) AS tag_count,
    COALESCE(plc.postlink_count, 0) AS postlink_count,
    RANK() OVER (ORDER BY u.reputation DESC) AS reputation_rank
FROM users u
LEFT JOIN badge_counts bc      ON bc.user_id = u.id
LEFT JOIN question_counts qc   ON qc.user_id = u.id
LEFT JOIN answer_counts ac     ON ac.user_id = u.id
LEFT JOIN post_avg_score pas   ON pas.user_id = u.id
LEFT JOIN comment_counts cc    ON cc.user_id = u.id
LEFT JOIN received_votes rv    ON rv.user_id = u.id
LEFT JOIN tag_counts tc        ON tc.user_id = u.id
LEFT JOIN postlink_counts plc  ON plc.user_id = u.id
WHERE COALESCE(bc.badge_count, 0) >= 3
  AND COALESCE(qc.question_count, 0) >= 5
  AND COALESCE(pas.avg_post_score, 0) > 5
ORDER BY u.reputation DESC
LIMIT 10

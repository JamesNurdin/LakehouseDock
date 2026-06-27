WITH user_base AS (
    SELECT id, reputation, creationdate, views, upvotes, downvotes
    FROM users
),
post_metrics AS (
    SELECT p.owneruserid AS userid,
           COUNT(p.id) AS post_count,
           SUM(p.score) AS total_post_score,
           AVG(p.score) AS avg_post_score,
           COUNT(DISTINCT CASE WHEN p.posttypeid = 1 THEN p.id END) AS question_count,
           COUNT(DISTINCT CASE WHEN p.posttypeid = 2 THEN p.id END) AS answer_count,
           SUM(p.answercount) AS total_answer_count,
           AVG(p.answercount) AS avg_answer_count
    FROM posts p
    GROUP BY p.owneruserid
),
comment_metrics AS (
    SELECT c.userid AS userid,
           COUNT(c.id) AS comment_made_count
    FROM comments c
    GROUP BY c.userid
),
comment_received_metrics AS (
    SELECT p.owneruserid AS userid,
           COUNT(c.id) AS comment_received_count
    FROM comments c
    JOIN posts p ON c.postid = p.id
    GROUP BY p.owneruserid
),
vote_cast_metrics AS (
    SELECT v.userid AS userid,
           COUNT(v.id) AS votes_cast_count,
           SUM(CASE WHEN v.votetypeid = 2 THEN 1 ELSE 0 END) AS upvotes_cast,
           SUM(CASE WHEN v.votetypeid = 3 THEN 1 ELSE 0 END) AS downvotes_cast
    FROM votes v
    GROUP BY v.userid
),
vote_received_metrics AS (
    SELECT p.owneruserid AS userid,
           COUNT(v.id) AS votes_received_count,
           SUM(CASE WHEN v.votetypeid = 2 THEN 1 ELSE 0 END) AS upvotes_received,
           SUM(CASE WHEN v.votetypeid = 3 THEN 1 ELSE 0 END) AS downvotes_received
    FROM votes v
    JOIN posts p ON v.postid = p.id
    GROUP BY p.owneruserid
),
badge_metrics AS (
    SELECT b.userid AS userid,
           COUNT(b.id) AS badge_count
    FROM badges b
    GROUP BY b.userid
),
tag_metrics AS (
    SELECT p.owneruserid AS userid,
           COUNT(DISTINCT t.id) AS distinct_tag_count
    FROM tags t
    JOIN posts p ON t.excerptpostid = p.id
    GROUP BY p.owneruserid
)
SELECT u.id AS user_id,
       u.reputation,
       u.creationdate,
       u.views,
       u.upvotes,
       u.downvotes,
       COALESCE(pm.post_count, 0) AS post_count,
       COALESCE(pm.total_post_score, 0) AS total_post_score,
       COALESCE(pm.avg_post_score, 0) AS avg_post_score,
       COALESCE(pm.question_count, 0) AS question_count,
       COALESCE(pm.answer_count, 0) AS answer_count,
       COALESCE(pm.total_answer_count, 0) AS total_answer_count,
       COALESCE(pm.avg_answer_count, 0) AS avg_answer_count,
       COALESCE(cm.comment_made_count, 0) AS comment_made_count,
       COALESCE(crm.comment_received_count, 0) AS comment_received_count,
       COALESCE(vcm.votes_cast_count, 0) AS votes_cast_count,
       COALESCE(vcm.upvotes_cast, 0) AS upvotes_cast,
       COALESCE(vcm.downvotes_cast, 0) AS downvotes_cast,
       COALESCE(vrm.votes_received_count, 0) AS votes_received_count,
       COALESCE(vrm.upvotes_received, 0) AS upvotes_received,
       COALESCE(vrm.downvotes_received, 0) AS downvotes_received,
       COALESCE(bm.badge_count, 0) AS badge_count,
       COALESCE(tm.distinct_tag_count, 0) AS distinct_tag_count
FROM user_base u
LEFT JOIN post_metrics pm      ON pm.userid = u.id
LEFT JOIN comment_metrics cm   ON cm.userid = u.id
LEFT JOIN comment_received_metrics crm ON crm.userid = u.id
LEFT JOIN vote_cast_metrics vcm ON vcm.userid = u.id
LEFT JOIN vote_received_metrics vrm ON vrm.userid = u.id
LEFT JOIN badge_metrics bm     ON bm.userid = u.id
LEFT JOIN tag_metrics tm       ON tm.userid = u.id
ORDER BY u.reputation DESC
LIMIT 100

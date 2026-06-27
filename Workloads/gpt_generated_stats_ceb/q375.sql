WITH comments_agg AS (
    SELECT postid,
           COUNT(*) AS comment_count,
           SUM(score) AS comment_score_sum
    FROM comments
    GROUP BY postid
),
votes_agg AS (
    SELECT postid,
           COUNT(*) AS vote_count,
           SUM(CASE WHEN votetypeid = 2 THEN 1 ELSE 0 END) AS upvote_count,
           SUM(CASE WHEN votetypeid = 3 THEN 1 ELSE 0 END) AS downvote_count,
           COUNT(DISTINCT userid) AS distinct_voter_count
    FROM votes
    GROUP BY postid
),
posthistory_agg AS (
    SELECT posthistorytypeid AS postid,
           COUNT(*) AS edit_count,
           COUNT(DISTINCT userid) AS distinct_editor_count
    FROM posthistory
    GROUP BY posthistorytypeid
),
posts_agg AS (
    SELECT p.id AS post_id,
           p.owneruserid,
           p.score AS post_score,
           p.answercount,
           COALESCE(ca.comment_count, 0) AS comment_count,
           COALESCE(ca.comment_score_sum, 0) AS comment_score_sum,
           COALESCE(va.vote_count, 0) AS vote_count,
           COALESCE(va.upvote_count, 0) AS upvote_count,
           COALESCE(va.downvote_count, 0) AS downvote_count,
           COALESCE(va.distinct_voter_count, 0) AS distinct_voter_count,
           COALESCE(ph.edit_count, 0) AS edit_count,
           COALESCE(ph.distinct_editor_count, 0) AS distinct_editor_count
    FROM posts p
    LEFT JOIN comments_agg ca ON ca.postid = p.id
    LEFT JOIN votes_agg va ON va.postid = p.id
    LEFT JOIN posthistory_agg ph ON ph.postid = p.id
)
SELECT u.id AS user_id,
       u.reputation,
       COUNT(p.post_id) AS total_posts,
       COALESCE(SUM(p.post_score), 0) AS total_post_score,
       AVG(p.post_score) AS avg_post_score,
       COALESCE(SUM(p.comment_count), 0) AS total_comments,
       COALESCE(SUM(p.comment_score_sum), 0) AS total_comment_score,
       COALESCE(SUM(p.vote_count), 0) AS total_votes,
       COALESCE(SUM(p.upvote_count), 0) AS total_upvotes,
       COALESCE(SUM(p.downvote_count), 0) AS total_downvotes,
       COALESCE(SUM(p.distinct_voter_count), 0) AS total_distinct_voters,
       COALESCE(SUM(p.edit_count), 0) AS total_edits,
       COALESCE(SUM(p.distinct_editor_count), 0) AS total_distinct_editors,
       COALESCE(SUM(p.answercount), 0) AS total_answers
FROM posts_agg p
JOIN users u ON u.id = p.owneruserid
GROUP BY u.id, u.reputation
ORDER BY total_posts DESC
LIMIT 20

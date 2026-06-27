WITH badge_counts AS (
    SELECT userid,
           COUNT(*) AS badge_count
    FROM badges
    GROUP BY userid
),
comment_stats AS (
    SELECT userid,
           COUNT(*) AS comment_count,
           SUM(score) AS total_comment_score,
           AVG(score) AS avg_comment_score
    FROM comments
    GROUP BY userid
),
vote_stats AS (
    SELECT userid,
           COUNT(*) AS vote_count,
           SUM(CASE WHEN votetypeid = 1 THEN 1 ELSE 0 END) AS upvote_count,
           SUM(CASE WHEN votetypeid = 2 THEN 1 ELSE 0 END) AS downvote_count,
           SUM(bountyamount) AS total_bounty
    FROM votes
    GROUP BY userid
),
posthistory_stats AS (
    SELECT userid,
           COUNT(*) AS posthistory_count,
           COUNT(DISTINCT posthistorytypeid) AS distinct_history_types
    FROM posthistory
    GROUP BY userid
)
SELECT u.id AS user_id,
       u.reputation,
       u.creationdate,
       ROW_NUMBER() OVER (ORDER BY u.reputation DESC) AS reputation_rank,
       COALESCE(bc.badge_count, 0) AS badge_count,
       COALESCE(cs.comment_count, 0) AS comment_count,
       COALESCE(cs.total_comment_score, 0) AS total_comment_score,
       COALESCE(cs.avg_comment_score, 0) AS avg_comment_score,
       COALESCE(vs.vote_count, 0) AS vote_count,
       COALESCE(vs.upvote_count, 0) AS upvote_count,
       COALESCE(vs.downvote_count, 0) AS downvote_count,
       COALESCE(vs.total_bounty, 0) AS total_bounty,
       COALESCE(ps.posthistory_count, 0) AS posthistory_count,
       COALESCE(ps.distinct_history_types, 0) AS distinct_history_types
FROM users u
LEFT JOIN badge_counts bc ON bc.userid = u.id
LEFT JOIN comment_stats cs ON cs.userid = u.id
LEFT JOIN vote_stats vs ON vs.userid = u.id
LEFT JOIN posthistory_stats ps ON ps.userid = u.id
ORDER BY u.reputation DESC
LIMIT 100

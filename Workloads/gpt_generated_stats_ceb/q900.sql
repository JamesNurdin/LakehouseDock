WITH comment_stats AS (
    SELECT userid,
           count(*) AS comment_count,
           avg(score) AS avg_comment_score,
           sum(score) AS total_comment_score
    FROM comments
    GROUP BY userid
),
vote_stats AS (
    SELECT userid,
           count(*) AS vote_count,
           sum(CASE WHEN votetypeid = 1 THEN 1 ELSE 0 END) AS upvote_count,
           sum(CASE WHEN votetypeid = 2 THEN 1 ELSE 0 END) AS downvote_count,
           sum(bountyamount) AS total_bounty_amount
    FROM votes
    GROUP BY userid
),
badge_stats AS (
    SELECT userid,
           count(*) AS badge_count
    FROM badges
    GROUP BY userid
)
SELECT u.id,
       u.reputation,
       u.creationdate,
       u.upvotes,
       u.downvotes,
       (u.upvotes - u.downvotes) AS net_upvotes,
       COALESCE(cs.comment_count, 0) AS comment_count,
       COALESCE(cs.avg_comment_score, 0) AS avg_comment_score,
       COALESCE(vs.vote_count, 0) AS vote_count,
       COALESCE(vs.upvote_count, 0) AS upvote_count,
       COALESCE(vs.downvote_count, 0) AS downvote_count,
       COALESCE(vs.total_bounty_amount, 0) AS total_bounty_amount,
       COALESCE(bs.badge_count, 0) AS badge_count
FROM users u
LEFT JOIN comment_stats cs ON cs.userid = u.id
LEFT JOIN vote_stats vs ON vs.userid = u.id
LEFT JOIN badge_stats bs ON bs.userid = u.id
WHERE u.reputation > 1000
ORDER BY comment_count DESC, vote_count DESC
LIMIT 100

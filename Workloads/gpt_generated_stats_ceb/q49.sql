WITH post_comment_stats AS (
    SELECT
        postid,
        COUNT(*) AS comment_cnt,
        SUM(score) AS comment_score_sum,
        AVG(score) AS comment_score_avg
    FROM comments
    GROUP BY postid
),
post_vote_stats AS (
    SELECT
        postid,
        COUNT(*) AS vote_cnt,
        SUM(bountyamount) AS total_bounty,
        SUM(CASE WHEN votetypeid = 1 THEN 1 ELSE 0 END) AS upvote_cnt,
        SUM(CASE WHEN votetypeid = 2 THEN 1 ELSE 0 END) AS downvote_cnt
    FROM votes
    GROUP BY postid
)
SELECT
    u.id AS user_id,
    u.reputation,
    COUNT(p.id) AS posts_owned,
    SUM(p.score) AS total_post_score,
    SUM(COALESCE(pcs.comment_cnt, 0)) AS total_comments_on_posts,
    SUM(COALESCE(pcs.comment_score_sum, 0)) AS total_comment_score_on_posts,
    SUM(COALESCE(pvs.vote_cnt, 0)) AS total_votes_on_posts,
    SUM(COALESCE(pvs.total_bounty, 0)) AS total_bounty_on_posts
FROM posts p
LEFT JOIN post_comment_stats pcs ON p.id = pcs.postid
LEFT JOIN post_vote_stats pvs ON p.id = pvs.postid
JOIN users u ON p.owneruserid = u.id
GROUP BY u.id, u.reputation
HAVING COUNT(p.id) >= 5
ORDER BY total_post_score DESC
LIMIT 100

WITH
    post_comments_agg AS (
        SELECT
            postid,
            COUNT(*) AS comment_count,
            SUM(score) AS comment_score
        FROM comments
        GROUP BY postid
    ),
    post_votes_agg AS (
        SELECT
            postid,
            COUNT(*) AS vote_count,
            SUM(CASE WHEN votetypeid = 1 THEN 1 ELSE 0 END) AS upvote_count,
            SUM(CASE WHEN votetypeid = 2 THEN 1 ELSE 0 END) AS downvote_count,
            SUM(bountyamount) AS total_bounty
        FROM votes
        GROUP BY postid
    ),
    post_history_agg AS (
        SELECT
            posthistorytypeid AS postid,
            COUNT(*) AS history_count
        FROM posthistory
        GROUP BY posthistorytypeid
    )
SELECT
    t.id AS tag_id,
    t.count AS tag_usage_count,
    COUNT(DISTINCT p.id) AS post_count,
    SUM(p.score) AS sum_post_score,
    SUM(COALESCE(pc.comment_score, 0)) AS sum_comment_score,
    SUM(COALESCE(pv.vote_count, 0)) AS sum_vote_count,
    SUM(COALESCE(pv.upvote_count, 0)) AS sum_upvote_count,
    SUM(COALESCE(pv.downvote_count, 0)) AS sum_downvote_count,
    SUM(COALESCE(pv.total_bounty, 0)) AS sum_bounty_amount,
    SUM(COALESCE(ph.history_count, 0)) AS sum_history_count,
    AVG(u.reputation) AS avg_owner_reputation
FROM tags t
JOIN posts p
    ON t.excerptpostid = p.id
LEFT JOIN post_comments_agg pc
    ON pc.postid = p.id
LEFT JOIN post_votes_agg pv
    ON pv.postid = p.id
LEFT JOIN post_history_agg ph
    ON ph.postid = p.id
LEFT JOIN users u
    ON p.owneruserid = u.id
GROUP BY
    t.id,
    t.count
ORDER BY sum_post_score DESC
LIMIT 10

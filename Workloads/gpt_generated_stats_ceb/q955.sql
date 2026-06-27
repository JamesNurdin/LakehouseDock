WITH comment_agg AS (
    SELECT postid,
        COUNT(*) AS comment_cnt,
        SUM(score) AS comment_score_sum
    FROM comments
    GROUP BY postid
),
vote_agg AS (
    SELECT postid,
        COUNT(*) AS vote_cnt,
        SUM(bountyamount) AS bounty_sum
    FROM votes
    GROUP BY postid
),
history_agg AS (
    SELECT posthistorytypeid AS postid,
        COUNT(*) AS history_cnt
    FROM posthistory
    GROUP BY posthistorytypeid
)
SELECT
    DATE_TRUNC('day', p.creationdate) AS post_date,
    p.posttypeid,
    COUNT(*) AS post_cnt,
    SUM(p.viewcount) AS total_viewcount,
    AVG(p.score) AS avg_post_score,
    SUM(COALESCE(c.comment_cnt, 0)) AS total_comments,
    SUM(COALESCE(c.comment_score_sum, 0)) AS total_comment_score,
    SUM(COALESCE(v.vote_cnt, 0)) AS total_votes,
    SUM(COALESCE(v.bounty_sum, 0)) AS total_bounty_amount,
    SUM(COALESCE(h.history_cnt, 0)) AS total_post_history_entries
FROM posts p
LEFT JOIN comment_agg c ON c.postid = p.id
LEFT JOIN vote_agg v ON v.postid = p.id
LEFT JOIN history_agg h ON h.postid = p.id
GROUP BY DATE_TRUNC('day', p.creationdate), p.posttypeid
ORDER BY post_date DESC, p.posttypeid

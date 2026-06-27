WITH post_aggregates AS (
    SELECT
        id,
        posttypeid,
        creationdate,
        score,
        viewcount,
        owneruserid,
        answercount,
        commentcount,
        favoritecount,
        lasteditoruserid
    FROM posts
),
vote_aggregates AS (
    SELECT
        postid,
        COUNT(*) AS vote_count,
        COUNT(DISTINCT userid) AS distinct_voter_count,
        SUM(CASE WHEN votetypeid = 2 THEN 1 ELSE 0 END) AS upvote_count,
        SUM(CASE WHEN votetypeid = 3 THEN 1 ELSE 0 END) AS downvote_count,
        SUM(bountyamount) AS total_bounty_amount
    FROM votes
    GROUP BY postid
)
SELECT
    p.posttypeid,
    COUNT(DISTINCT p.id) AS total_posts,
    AVG(p.score) AS avg_score,
    SUM(p.viewcount) AS total_views,
    SUM(COALESCE(v.vote_count, 0)) AS total_votes,
    SUM(COALESCE(v.distinct_voter_count, 0)) AS total_distinct_voters,
    SUM(COALESCE(v.upvote_count, 0)) AS total_upvotes,
    SUM(COALESCE(v.downvote_count, 0)) AS total_downvotes,
    SUM(COALESCE(v.total_bounty_amount, 0)) AS total_bounty_amount,
    (SUM(COALESCE(v.upvote_count, 0)) * 1.0) / NULLIF(SUM(COALESCE(v.vote_count, 0)), 0) AS upvote_ratio
FROM post_aggregates p
LEFT JOIN vote_aggregates v
    ON v.postid = p.id
WHERE p.score > 0
GROUP BY p.posttypeid
ORDER BY total_posts DESC, avg_score DESC

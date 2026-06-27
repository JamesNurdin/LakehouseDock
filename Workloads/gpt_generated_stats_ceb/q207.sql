/* Top posts by vote count within each post type */
WITH post_aggregates AS (
    SELECT
        p.id AS post_id,
        p.posttypeid,
        p.owneruserid,
        p.score,
        p.viewcount,
        COUNT(v.id) AS vote_count,
        SUM(v.bountyamount) AS total_bounty_amount
    FROM posts p
    LEFT JOIN votes v
        ON v.postid = p.id
    GROUP BY
        p.id,
        p.posttypeid,
        p.owneruserid,
        p.score,
        p.viewcount
)
SELECT
    posttypeid,
    post_id,
    owneruserid,
    score,
    viewcount,
    vote_count,
    total_bounty_amount,
    RANK() OVER (PARTITION BY posttypeid ORDER BY vote_count DESC) AS vote_rank
FROM post_aggregates
WHERE vote_count > 0
ORDER BY posttypeid, vote_rank
LIMIT 20

WITH post_aggregates AS (
    SELECT
        p.id AS post_id,
        p.posttypeid,
        p.creationdate,
        p.score,
        p.viewcount,
        p.owneruserid,
        COUNT(v.id) AS vote_count,
        COALESCE(SUM(v.bountyamount), 0) AS total_bounty,
        COUNT(DISTINCT ph.id) AS posthistory_count,
        COUNT(DISTINCT t.id) AS tag_count
    FROM posts p
    LEFT JOIN votes v
        ON v.postid = p.id
    LEFT JOIN posthistory ph
        ON ph.posthistorytypeid = p.id
    LEFT JOIN tags t
        ON t.excerptpostid = p.id
    GROUP BY
        p.id,
        p.posttypeid,
        p.creationdate,
        p.score,
        p.viewcount,
        p.owneruserid
)
SELECT
    post_id,
    posttypeid,
    creationdate,
    score,
    viewcount,
    owneruserid,
    vote_count,
    total_bounty,
    posthistory_count,
    tag_count,
    (vote_count * 1.0) / NULLIF(viewcount, 0) AS votes_per_view,
    RANK() OVER (ORDER BY vote_count DESC) AS vote_rank
FROM post_aggregates
ORDER BY vote_count DESC
LIMIT 100

WITH post_stats AS (
    SELECT
        posttypeid,
        COUNT(*) AS post_count,
        AVG(score) AS avg_score,
        MAX(viewcount) AS max_viewcount,
        MIN(creationdate) AS earliest_creationdate,
        SUM(score) AS total_score
    FROM posts
    GROUP BY posttypeid
),
vote_stats AS (
    SELECT
        p.posttypeid,
        v.votetypeid,
        COUNT(*) AS vote_count,
        AVG(v.bountyamount) AS avg_bounty,
        SUM(v.bountyamount) AS total_bounty
    FROM votes v
    JOIN posts p ON v.postid = p.id
    GROUP BY p.posttypeid, v.votetypeid
)
SELECT
    ps.posttypeid,
    vs.votetypeid,
    ps.post_count,
    vs.vote_count,
    ps.avg_score,
    vs.avg_bounty,
    CASE WHEN ps.post_count > 0 THEN vs.vote_count * 1.0 / ps.post_count ELSE NULL END AS votes_per_post,
    ps.max_viewcount,
    ps.earliest_creationdate,
    ps.total_score,
    vs.total_bounty
FROM post_stats ps
JOIN vote_stats vs ON ps.posttypeid = vs.posttypeid
ORDER BY ps.posttypeid, vs.votetypeid

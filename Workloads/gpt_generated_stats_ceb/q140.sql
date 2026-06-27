WITH post_stats AS (
    SELECT
        p.owneruserid AS owneruserid,
        COUNT(*) AS post_count,
        SUM(p.score) AS total_post_score
    FROM posts p
    GROUP BY p.owneruserid
),
vote_stats AS (
    SELECT
        p.owneruserid AS owneruserid,
        COUNT(v.id) AS total_votes,
        SUM(v.bountyamount) AS total_bounty,
        AVG(u_voter.reputation) AS avg_voter_reputation,
        COUNT(DISTINCT v.userid) AS distinct_voter_count
    FROM posts p
    JOIN votes v ON v.postid = p.id
    JOIN users u_voter ON v.userid = u_voter.id
    GROUP BY p.owneruserid
)
SELECT
    u.id AS owner_user_id,
    u.reputation AS owner_reputation,
    ps.post_count,
    ps.total_post_score,
    vs.total_votes,
    vs.total_bounty,
    vs.avg_voter_reputation,
    vs.distinct_voter_count
FROM users u
LEFT JOIN post_stats ps ON u.id = ps.owneruserid
LEFT JOIN vote_stats vs ON u.id = vs.owneruserid
ORDER BY vs.total_votes DESC
LIMIT 100

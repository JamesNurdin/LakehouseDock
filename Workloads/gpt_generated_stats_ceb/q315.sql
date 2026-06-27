WITH tag_data AS (
    SELECT
        t.id AS tag_id,
        t."count" AS tag_count,
        p.id AS post_id,
        p.score AS post_score,
        p.creationdate AS post_creationdate,
        v.id AS vote_id,
        v.votetypeid,
        v.bountyamount,
        v.creationdate AS vote_creationdate,
        u.id AS voter_user_id,
        u.reputation AS voter_reputation,
        u.creationdate AS voter_creationdate,
        o.id AS owner_user_id,
        o.reputation AS owner_reputation
    FROM tags t
    JOIN posts p ON t.excerptpostid = p.id
    LEFT JOIN votes v ON v.postid = p.id
    LEFT JOIN users u ON v.userid = u.id
    LEFT JOIN users o ON p.owneruserid = o.id
)
SELECT
    tag_id,
    tag_count,
    COUNT(vote_id) AS total_votes,
    SUM(COALESCE(bountyamount, 0)) AS total_bounty,
    AVG(votetypeid) AS avg_vote_type,
    COUNT(DISTINCT voter_user_id) AS distinct_voters,
    AVG(voter_reputation) AS avg_voter_reputation,
    AVG(owner_reputation) AS avg_owner_reputation,
    MAX(post_score) AS excerpt_post_score,
    MIN(post_creationdate) AS earliest_excerpt_post_date
FROM tag_data
GROUP BY tag_id, tag_count
ORDER BY total_votes DESC
LIMIT 10

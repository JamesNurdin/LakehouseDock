WITH post_votes AS (
    SELECT
        postid,
        COUNT(*) AS vote_count,
        COUNT(DISTINCT userid) AS distinct_voter_count
    FROM votes
    GROUP BY postid
),
outbound_links AS (
    SELECT
        postid,
        COUNT(*) AS outbound_link_count
    FROM postlinks
    GROUP BY postid
),
inbound_links AS (
    SELECT
        relatedpostid AS postid,
        COUNT(*) AS inbound_link_count
    FROM postlinks
    GROUP BY relatedpostid
),
user_aggregates AS (
    SELECT
        p.owneruserid,
        COUNT(*) AS post_count,
        SUM(p.score) AS total_score,
        AVG(p.score) AS avg_score,
        SUM(p.viewcount) AS total_viewcount,
        SUM(COALESCE(v.vote_count, 0)) AS total_votes,
        SUM(COALESCE(v.distinct_voter_count, 0)) AS total_distinct_voters,
        SUM(COALESCE(o.outbound_link_count, 0)) AS total_outbound_links,
        SUM(COALESCE(i.inbound_link_count, 0)) AS total_inbound_links
    FROM posts p
    LEFT JOIN post_votes v ON v.postid = p.id
    LEFT JOIN outbound_links o ON o.postid = p.id
    LEFT JOIN inbound_links i ON i.postid = p.id
    GROUP BY p.owneruserid
)
SELECT
    u.id AS user_id,
    u.reputation,
    ua.post_count,
    ua.total_score,
    ua.avg_score,
    ua.total_viewcount,
    ua.total_votes,
    ua.total_distinct_voters,
    ua.total_outbound_links,
    ua.total_inbound_links
FROM users u
JOIN user_aggregates ua ON ua.owneruserid = u.id
ORDER BY ua.total_votes DESC
LIMIT 100

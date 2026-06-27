WITH vote_agg AS (
    SELECT
        postid,
        COUNT(*) AS vote_count,
        COUNT(DISTINCT userid) AS distinct_voter_count
    FROM votes
    GROUP BY postid
),
edit_agg AS (
    SELECT
        posthistorytypeid AS postid,
        COUNT(*) AS edit_count,
        COUNT(DISTINCT userid) AS distinct_editor_count
    FROM posthistory
    GROUP BY posthistorytypeid
)
SELECT
    t.id AS tag_id,
    t.count AS tag_count,
    COUNT(DISTINCT p.id) AS post_count,
    SUM(p.score) AS total_post_score,
    AVG(o.reputation) AS avg_owner_reputation,
    COALESCE(SUM(v.vote_count), 0) AS total_votes,
    COALESCE(SUM(v.distinct_voter_count), 0) AS total_distinct_voters,
    COALESCE(SUM(e.edit_count), 0) AS total_edits,
    COALESCE(SUM(e.distinct_editor_count), 0) AS total_distinct_editors
FROM tags t
LEFT JOIN posts p ON t.excerptpostid = p.id
LEFT JOIN users o ON p.owneruserid = o.id
LEFT JOIN vote_agg v ON v.postid = p.id
LEFT JOIN edit_agg e ON e.postid = p.id
GROUP BY t.id, t.count
ORDER BY total_votes DESC
LIMIT 20

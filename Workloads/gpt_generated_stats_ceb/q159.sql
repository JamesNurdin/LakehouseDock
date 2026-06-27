WITH post_vote_counts AS (
    SELECT
        postid,
        COUNT(*) AS total_votes
    FROM votes
    GROUP BY postid
),
post_edit_counts AS (
    SELECT
        ph.posthistorytypeid AS post_id,
        COUNT(*) AS edit_count,
        COUNT(DISTINCT ph.userid) AS distinct_editors
    FROM posthistory ph
    GROUP BY ph.posthistorytypeid
)
SELECT
    t.id AS tag_id,
    t.count AS tag_post_count,
    p.id AS excerpt_post_id,
    p.score AS excerpt_post_score,
    p.viewcount AS excerpt_post_views,
    COALESCE(v.total_votes, 0) AS excerpt_post_votes,
    COALESCE(e.edit_count, 0) AS excerpt_post_edit_count,
    COALESCE(e.distinct_editors, 0) AS excerpt_post_distinct_editors,
    u.reputation AS owner_reputation,
    u.creationdate AS owner_creationdate
FROM tags t
JOIN posts p
    ON t.excerptpostid = p.id
LEFT JOIN post_vote_counts v
    ON p.id = v.postid
LEFT JOIN post_edit_counts e
    ON p.id = e.post_id
JOIN users u
    ON p.owneruserid = u.id
ORDER BY t.count DESC, t.id

WITH vote_agg AS (
    SELECT
        postid,
        COUNT(*) AS vote_count,
        SUM(bountyamount) AS total_bounty,
        COUNT(DISTINCT userid) AS distinct_voter_count
    FROM votes
    GROUP BY postid
),
edit_agg AS (
    SELECT
        posthistorytypeid AS post_id,
        COUNT(*) AS edit_count,
        COUNT(DISTINCT userid) AS distinct_editor_user_count
    FROM posthistory
    GROUP BY posthistorytypeid
),
link_agg AS (
    SELECT
        postid,
        COUNT(*) AS link_count
    FROM postlinks
    GROUP BY postid
),
post_agg AS (
    SELECT
        p.id AS post_id,
        p.creationdate,
        p.score,
        p.owneruserid,
        p.lasteditoruserid,
        COALESCE(v.vote_count, 0) AS vote_count,
        COALESCE(v.total_bounty, 0) AS total_bounty,
        COALESCE(v.distinct_voter_count, 0) AS distinct_voter_count,
        COALESCE(e.edit_count, 0) AS edit_count,
        COALESCE(e.distinct_editor_user_count, 0) AS distinct_editor_user_count,
        COALESCE(l.link_count, 0) AS link_count
    FROM posts p
    LEFT JOIN vote_agg v ON v.postid = p.id
    LEFT JOIN edit_agg e ON e.post_id = p.id
    LEFT JOIN link_agg l ON l.postid = p.id
)
SELECT
    date_trunc('month', pa.creationdate) AS month,
    COUNT(*) AS total_posts,
    AVG(pa.score) AS avg_score,
    SUM(pa.vote_count) AS total_votes,
    SUM(pa.total_bounty) AS total_bounty_amount,
    SUM(pa.edit_count) AS total_edits,
    SUM(pa.link_count) AS total_links,
    COUNT(DISTINCT pa.owneruserid) AS distinct_post_authors,
    COUNT(DISTINCT pa.lasteditoruserid) AS distinct_last_editors,
    SUM(pa.distinct_voter_count) AS total_distinct_voters,
    SUM(pa.distinct_editor_user_count) AS total_distinct_editors
FROM post_agg pa
GROUP BY date_trunc('month', pa.creationdate)
ORDER BY month

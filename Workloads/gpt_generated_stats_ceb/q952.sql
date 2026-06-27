WITH post_comment_stats AS (
    SELECT
        postid,
        COUNT(*) AS comment_count,
        SUM(score) AS comment_score_sum
    FROM comments
    GROUP BY postid
),
post_vote_stats AS (
    SELECT
        postid,
        COUNT(*) AS vote_count,
        COUNT(DISTINCT userid) AS distinct_voter_count
    FROM votes
    GROUP BY postid
),
post_history_stats AS (
    SELECT
        posthistorytypeid AS postid,
        COUNT(*) AS history_count
    FROM posthistory
    GROUP BY posthistorytypeid
),
post_outgoing_link_stats AS (
    SELECT
        postid,
        COUNT(*) AS outgoing_link_count
    FROM postlinks
    GROUP BY postid
),
post_incoming_link_stats AS (
    SELECT
        relatedpostid AS postid,
        COUNT(*) AS incoming_link_count
    FROM postlinks
    GROUP BY relatedpostid
),
tag_excerpt_counts AS (
    SELECT
        p.owneruserid AS owner_user_id,
        COUNT(t.id) AS tag_excerpt_count
    FROM tags t
    JOIN posts p ON t.excerptpostid = p.id
    GROUP BY p.owneruserid
),
owner_aggregates AS (
    SELECT
        p.owneruserid AS owner_user_id,
        COUNT(p.id) AS post_count,
        SUM(p.score) AS total_post_score,
        AVG(p.score) AS avg_post_score,
        SUM(p.viewcount) AS total_view_count,
        SUM(COALESCE(pc.comment_count, 0)) AS total_comment_count,
        SUM(COALESCE(pv.vote_count, 0)) AS total_vote_count,
        SUM(COALESCE(pv.distinct_voter_count, 0)) AS total_distinct_voter_count,
        SUM(COALESCE(ph.history_count, 0)) AS total_history_count,
        SUM(COALESCE(pl.outgoing_link_count, 0) + COALESCE(pl_in.incoming_link_count, 0)) AS total_link_count
    FROM posts p
    LEFT JOIN post_comment_stats pc ON p.id = pc.postid
    LEFT JOIN post_vote_stats pv ON p.id = pv.postid
    LEFT JOIN post_history_stats ph ON p.id = ph.postid
    LEFT JOIN post_outgoing_link_stats pl ON p.id = pl.postid
    LEFT JOIN post_incoming_link_stats pl_in ON p.id = pl_in.postid
    GROUP BY p.owneruserid
)
SELECT
    u.id AS user_id,
    u.reputation,
    u.creationdate,
    COALESCE(oa.post_count, 0)                AS post_count,
    COALESCE(oa.total_post_score, 0)          AS total_post_score,
    oa.avg_post_score,
    COALESCE(oa.total_view_count, 0)          AS total_view_count,
    COALESCE(oa.total_comment_count, 0)       AS total_comment_count,
    COALESCE(oa.total_vote_count, 0)          AS total_vote_count,
    COALESCE(oa.total_distinct_voter_count, 0) AS total_distinct_voter_count,
    COALESCE(oa.total_history_count, 0)       AS total_history_count,
    COALESCE(oa.total_link_count, 0)          AS total_link_count,
    COALESCE(tc.tag_excerpt_count, 0)         AS tag_excerpt_count
FROM users u
LEFT JOIN owner_aggregates oa ON u.id = oa.owner_user_id
LEFT JOIN tag_excerpt_counts tc ON u.id = tc.owner_user_id
ORDER BY total_post_score DESC
LIMIT 100

-- Monthly activity summary across posts and related entities
WITH post_month AS (
    SELECT
        id,
        creationdate,
        score,
        owneruserid,
        lasteditoruserid
    FROM posts
),
comment_counts AS (
    SELECT
        postid,
        COUNT(*) AS comment_count
    FROM comments
    GROUP BY postid
),
vote_counts AS (
    SELECT
        postid,
        COUNT(*) AS vote_count
    FROM votes
    GROUP BY postid
),
tag_counts AS (
    SELECT
        excerptpostid AS postid,
        COUNT(*) AS tag_count
    FROM tags
    GROUP BY excerptpostid
),
posthistory_counts AS (
    SELECT
        posthistorytypeid AS postid,
        COUNT(*) AS history_count
    FROM posthistory
    GROUP BY posthistorytypeid
),
postlink_counts AS (
    SELECT
        postid,
        COUNT(*) AS link_count
    FROM postlinks
    GROUP BY postid
)
SELECT
    date_trunc('month', pm.creationdate) AS month,
    COUNT(*) AS post_count,
    SUM(pm.score) AS total_score,
    AVG(pm.score) AS avg_score,
    SUM(COALESCE(cc.comment_count, 0)) AS total_comments,
    SUM(COALESCE(vc.vote_count, 0)) AS total_votes,
    COUNT(DISTINCT pm.owneruserid) AS distinct_owners,
    COUNT(DISTINCT pm.lasteditoruserid) AS distinct_editors,
    SUM(COALESCE(tc.tag_count, 0)) AS total_tags,
    SUM(COALESCE(phc.history_count, 0)) AS total_history_events,
    SUM(COALESCE(plc.link_count, 0)) AS total_links
FROM post_month pm
LEFT JOIN comment_counts cc
    ON cc.postid = pm.id
LEFT JOIN vote_counts vc
    ON vc.postid = pm.id
LEFT JOIN tag_counts tc
    ON tc.postid = pm.id
LEFT JOIN posthistory_counts phc
    ON phc.postid = pm.id
LEFT JOIN postlink_counts plc
    ON plc.postid = pm.id
GROUP BY date_trunc('month', pm.creationdate)
ORDER BY month

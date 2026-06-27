WITH comment_agg AS (
    SELECT
        postid,
        SUM(score) AS total_comment_score,
        COUNT(*) AS comment_count,
        COUNT(DISTINCT userid) AS distinct_comment_user_count
    FROM comments
    GROUP BY postid
),
posthistory_agg AS (
    SELECT
        posthistorytypeid AS post_id,
        COUNT(*) AS posthistory_count
    FROM posthistory
    GROUP BY posthistorytypeid
),
postlinks_out_agg AS (
    SELECT
        postid AS post_id,
        COUNT(*) AS postlinks_outgoing_count
    FROM postlinks
    GROUP BY postid
),
postlinks_in_agg AS (
    SELECT
        relatedpostid AS post_id,
        COUNT(*) AS postlinks_incoming_count
    FROM postlinks
    GROUP BY relatedpostid
),
tag_agg AS (
    SELECT
        excerptpostid AS post_id,
        SUM(count) AS tag_total_count
    FROM tags
    GROUP BY excerptpostid
)

SELECT
    p.id AS post_id,
    p.posttypeid,
    p.creationdate,
    p.score AS post_score,
    p.viewcount,
    p.owneruserid,
    p.answercount,
    p.commentcount,
    p.favoritecount,
    p.lasteditoruserid,
    COALESCE(ca.total_comment_score, 0) AS total_comment_score,
    COALESCE(ca.distinct_comment_user_count, 0) AS distinct_comment_user_count,
    COALESCE(ph.posthistory_count, 0) AS posthistory_count,
    COALESCE(pl_out.postlinks_outgoing_count, 0) AS postlinks_outgoing_count,
    COALESCE(pl_in.postlinks_incoming_count, 0) AS postlinks_incoming_count,
    COALESCE(tg.tag_total_count, 0) AS tag_total_count
FROM posts p
LEFT JOIN comment_agg ca ON ca.postid = p.id
LEFT JOIN posthistory_agg ph ON ph.post_id = p.id
LEFT JOIN postlinks_out_agg pl_out ON pl_out.post_id = p.id
LEFT JOIN postlinks_in_agg pl_in ON pl_in.post_id = p.id
LEFT JOIN tag_agg tg ON tg.post_id = p.id
WHERE COALESCE(ca.total_comment_score, 0) > 0
ORDER BY total_comment_score DESC
LIMIT 100

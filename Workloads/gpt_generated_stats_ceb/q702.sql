WITH comment_agg AS (
    SELECT
        postid,
        COUNT(*) AS comment_cnt,
        SUM(score) AS comment_score_sum,
        AVG(score) AS comment_score_avg
    FROM comments
    GROUP BY postid
),
postlink_out_agg AS (
    SELECT
        postid,
        COUNT(*) AS outbound_link_cnt,
        SUM(linktypeid) AS outbound_linktype_sum
    FROM postlinks
    GROUP BY postid
),
postlink_in_agg AS (
    SELECT
        relatedpostid,
        COUNT(*) AS inbound_link_cnt,
        SUM(linktypeid) AS inbound_linktype_sum
    FROM postlinks
    GROUP BY relatedpostid
)
SELECT
    p.id AS post_id,
    p.posttypeid,
    p.creationdate,
    p.owneruserid,
    p.score AS post_score,
    p.viewcount,
    p.answercount,
    p.commentcount,
    p.favoritecount,
    p.lasteditoruserid,
    COALESCE(ca.comment_cnt, 0) AS comment_cnt_derived,
    COALESCE(ca.comment_score_sum, 0) AS comment_score_sum,
    COALESCE(ca.comment_score_avg, 0) AS comment_score_avg,
    COALESCE(pl_out.outbound_link_cnt, 0) AS outbound_link_cnt,
    COALESCE(pl_out.outbound_linktype_sum, 0) AS outbound_linktype_sum,
    COALESCE(pl_in.inbound_link_cnt, 0) AS inbound_link_cnt,
    COALESCE(pl_in.inbound_linktype_sum, 0) AS inbound_linktype_sum,
    (COALESCE(pl_out.outbound_link_cnt, 0) + COALESCE(pl_in.inbound_link_cnt, 0)) AS total_link_cnt
FROM posts p
LEFT JOIN comment_agg ca ON ca.postid = p.id
LEFT JOIN postlink_out_agg pl_out ON pl_out.postid = p.id
LEFT JOIN postlink_in_agg pl_in ON pl_in.relatedpostid = p.id
WHERE p.posttypeid = 1
ORDER BY p.creationdate DESC
LIMIT 100

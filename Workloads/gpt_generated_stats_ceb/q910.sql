WITH comment_agg AS (
    SELECT
        postid,
        COUNT(*) AS comment_count,
        AVG(score) AS avg_comment_score,
        SUM(score) AS sum_comment_score
    FROM comments
    GROUP BY postid
),
posthistory_agg AS (
    SELECT
        posthistorytypeid,
        COUNT(*) AS posthistory_count
    FROM posthistory
    GROUP BY posthistorytypeid
),
postlinks_src_agg AS (
    SELECT
        postid,
        COUNT(*) AS outlink_count
    FROM postlinks
    GROUP BY postid
),
postlinks_tgt_agg AS (
    SELECT
        relatedpostid,
        COUNT(*) AS inlink_count
    FROM postlinks
    GROUP BY relatedpostid
),
tags_agg AS (
    SELECT
        excerptpostid,
        COUNT(*) AS tag_count
    FROM tags
    GROUP BY excerptpostid
)
SELECT
    p.id,
    p.posttypeid,
    p.creationdate,
    p.score,
    p.viewcount,
    p.owneruserid,
    p.answercount,
    p.commentcount,
    p.favoritecount,
    COALESCE(c.comment_count, 0) AS comment_count,
    COALESCE(c.avg_comment_score, 0.0) AS avg_comment_score,
    COALESCE(ph.posthistory_count, 0) AS posthistory_count,
    COALESCE(pls.outlink_count, 0) AS outlink_count,
    COALESCE(plt.inlink_count, 0) AS inlink_count,
    COALESCE(t.tag_count, 0) AS tag_count
FROM posts p
LEFT JOIN comment_agg c ON c.postid = p.id
LEFT JOIN posthistory_agg ph ON ph.posthistorytypeid = p.id
LEFT JOIN postlinks_src_agg pls ON pls.postid = p.id
LEFT JOIN postlinks_tgt_agg plt ON plt.relatedpostid = p.id
LEFT JOIN tags_agg t ON t.excerptpostid = p.id
ORDER BY p.creationdate DESC
LIMIT 100

WITH comment_stats AS (
    SELECT
        postid AS post_id,
        COUNT(*) AS comment_cnt,
        SUM(score) AS comment_score_sum,
        COUNT(DISTINCT userid) AS distinct_commenters
    FROM comments
    GROUP BY postid
),
edit_stats AS (
    SELECT
        posthistorytypeid AS post_id,
        COUNT(*) AS edit_cnt
    FROM posthistory
    GROUP BY posthistorytypeid
),
link_stats AS (
    SELECT
        post_id,
        SUM(outbound_cnt) AS outbound_cnt,
        SUM(inbound_cnt) AS inbound_cnt
    FROM (
        SELECT
            postid AS post_id,
            COUNT(*) AS outbound_cnt,
            0 AS inbound_cnt
        FROM postlinks
        GROUP BY postid
        UNION ALL
        SELECT
            relatedpostid AS post_id,
            0 AS outbound_cnt,
            COUNT(*) AS inbound_cnt
        FROM postlinks
        GROUP BY relatedpostid
    ) t
    GROUP BY post_id
)
SELECT
    p.id AS post_id,
    p.creationdate AS post_created,
    p.score AS post_score,
    p.viewcount,
    p.answercount,
    p.commentcount AS post_commentcount,
    p.favoritecount,
    owner_user.reputation AS owner_reputation,
    editor_user.reputation AS last_editor_reputation,
    COALESCE(cs.comment_cnt, 0) AS total_comments,
    COALESCE(cs.comment_score_sum, 0) AS total_comment_score,
    COALESCE(cs.distinct_commenters, 0) AS distinct_commenters,
    CASE WHEN COALESCE(cs.comment_cnt, 0) > 0 THEN COALESCE(cs.comment_score_sum, 0) / COALESCE(cs.comment_cnt, 0) END AS avg_comment_score,
    COALESCE(es.edit_cnt, 0) AS total_edits,
    COALESCE(ls.outbound_cnt, 0) AS outbound_links,
    COALESCE(ls.inbound_cnt, 0) AS inbound_links,
    COALESCE(ls.outbound_cnt, 0) + COALESCE(ls.inbound_cnt, 0) AS total_links
FROM posts p
LEFT JOIN users owner_user ON p.owneruserid = owner_user.id
LEFT JOIN users editor_user ON p.lasteditoruserid = editor_user.id
LEFT JOIN comment_stats cs ON p.id = cs.post_id
LEFT JOIN edit_stats es ON p.id = es.post_id
LEFT JOIN link_stats ls ON p.id = ls.post_id
ORDER BY total_edits DESC, post_score DESC
LIMIT 100

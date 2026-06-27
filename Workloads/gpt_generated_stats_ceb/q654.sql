WITH comment_agg AS (
    SELECT
        c.postid AS post_id,
        COUNT(c.id) AS comment_cnt,
        SUM(c.score) AS comment_score_sum
    FROM comments c
    GROUP BY c.postid
),
outbound_link_agg AS (
    SELECT
        pl.postid AS post_id,
        COUNT(pl.id) AS outbound_link_cnt
    FROM postlinks pl
    GROUP BY pl.postid
),
inbound_link_agg AS (
    SELECT
        pl.relatedpostid AS post_id,
        COUNT(pl.id) AS inbound_link_cnt
    FROM postlinks pl
    GROUP BY pl.relatedpostid
),
post_agg AS (
    SELECT
        p.id AS post_id,
        date_trunc('month', p.creationdate) AS post_month,
        p.score AS post_score,
        p.viewcount AS view_count,
        p.answercount AS answer_cnt,
        p.commentcount AS post_comment_cnt,
        p.favoritecount AS fav_cnt
    FROM posts p
    WHERE p.posttypeid = 1
)
SELECT
    pa.post_id,
    pa.post_month,
    pa.post_score,
    COALESCE(ca.comment_score_sum, 0) AS total_comment_score,
    COALESCE(ca.comment_cnt, 0) AS total_comment_cnt,
    COALESCE(ol.outbound_link_cnt, 0) AS outbound_link_cnt,
    COALESCE(il.inbound_link_cnt, 0) AS inbound_link_cnt,
    (pa.post_score * 0.5
        + COALESCE(ca.comment_score_sum, 0) * 0.3
        + COALESCE(ol.outbound_link_cnt, 0) * 0.1
        + COALESCE(il.inbound_link_cnt, 0) * 0.1) AS weighted_engagement_score,
    row_number() OVER (ORDER BY
        (pa.post_score * 0.5
            + COALESCE(ca.comment_score_sum, 0) * 0.3
            + COALESCE(ol.outbound_link_cnt, 0) * 0.1
            + COALESCE(il.inbound_link_cnt, 0) * 0.1) DESC) AS rank
FROM post_agg pa
LEFT JOIN comment_agg ca ON ca.post_id = pa.post_id
LEFT JOIN outbound_link_agg ol ON ol.post_id = pa.post_id
LEFT JOIN inbound_link_agg il ON il.post_id = pa.post_id
ORDER BY rank
LIMIT 10

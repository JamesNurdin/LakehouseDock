WITH post_metrics AS (
    SELECT
        id,
        posttypeid,
        score,
        viewcount,
        answercount,
        commentcount,
        favoritecount
    FROM posts
),
link_aggregates AS (
    SELECT
        pl.linktypeid,
        src.posttypeid AS src_posttype,
        tgt.posttypeid AS tgt_posttype,
        COUNT(*) AS total_links,
        SUM(src.score) AS src_total_score,
        SUM(tgt.score) AS tgt_total_score,
        AVG(src.answercount) AS src_avg_answers,
        AVG(tgt.answercount) AS tgt_avg_answers
    FROM postlinks pl
    JOIN post_metrics src ON pl.postid = src.id
    JOIN post_metrics tgt ON pl.relatedpostid = tgt.id
    GROUP BY pl.linktypeid, src.posttypeid, tgt.posttypeid
)
SELECT
    linktypeid,
    src_posttype,
    tgt_posttype,
    total_links,
    src_total_score,
    tgt_total_score,
    src_avg_answers,
    tgt_avg_answers
FROM link_aggregates
ORDER BY total_links DESC
LIMIT 20

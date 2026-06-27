WITH post_base AS (
    SELECT
        id,
        posttypeid,
        score AS post_score,
        viewcount,
        answercount,
        commentcount,
        favoritecount,
        creationdate AS post_creationdate
    FROM posts
),
comment_agg AS (
    SELECT
        p.posttypeid,
        COUNT(c.id) AS comment_cnt,
        SUM(c.score) AS comment_score_sum,
        AVG(c.score) AS comment_score_avg
    FROM comments c
    JOIN post_base p ON c.postid = p.id
    GROUP BY p.posttypeid
),
posthistory_agg AS (
    SELECT
        p.posttypeid,
        COUNT(ph.id) AS posthistory_cnt,
        COUNT(DISTINCT ph.userid) AS posthistory_user_cnt
    FROM posthistory ph
    JOIN post_base p ON ph.posthistorytypeid = p.id
    GROUP BY p.posttypeid
),
tag_agg AS (
    SELECT
        p.posttypeid,
        COUNT(t.id) AS tag_cnt,
        SUM(t.count) AS tag_usage_sum
    FROM tags t
    JOIN post_base p ON t.excerptpostid = p.id
    GROUP BY p.posttypeid
),
post_type_agg AS (
    SELECT
        posttypeid,
        COUNT(id) AS post_cnt,
        SUM(post_score) AS post_score_sum,
        AVG(post_score) AS post_score_avg,
        SUM(viewcount) AS viewcount_sum,
        AVG(viewcount) AS viewcount_avg
    FROM post_base
    GROUP BY posttypeid
)
SELECT
    pt.posttypeid,
    pt.post_cnt,
    pt.post_score_sum,
    pt.post_score_avg,
    pt.viewcount_sum,
    pt.viewcount_avg,
    co.comment_cnt,
    co.comment_score_sum,
    co.comment_score_avg,
    ph.posthistory_cnt,
    ph.posthistory_user_cnt,
    tg.tag_cnt,
    tg.tag_usage_sum
FROM post_type_agg pt
LEFT JOIN comment_agg co ON pt.posttypeid = co.posttypeid
LEFT JOIN posthistory_agg ph ON pt.posttypeid = ph.posttypeid
LEFT JOIN tag_agg tg ON pt.posttypeid = tg.posttypeid
ORDER BY pt.posttypeid

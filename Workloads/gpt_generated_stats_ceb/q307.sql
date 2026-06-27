WITH post_metrics AS (
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
        -- comment aggregates
        COUNT(DISTINCT c.id) AS comment_cnt,
        COALESCE(SUM(c.score), 0) AS comment_score_sum,
        -- vote aggregates
        COUNT(DISTINCT v.id) AS vote_cnt,
        COALESCE(SUM(CASE WHEN v.votetypeid = 1 THEN 1 ELSE 0 END), 0) AS upvote_cnt,
        COALESCE(SUM(CASE WHEN v.votetypeid = 2 THEN 1 ELSE 0 END), 0) AS downvote_cnt,
        -- post‑link aggregates (outgoing links)
        COUNT(DISTINCT pl.id) AS outlink_cnt,
        -- post‑link aggregates (incoming links)
        COUNT(DISTINCT pl2.id) AS inlink_cnt,
        -- tag popularity (use the highest tag count for the post)
        COALESCE(MAX(t.count), 0) AS tag_popularity
    FROM posts p
    LEFT JOIN comments c       ON c.postid      = p.id
    LEFT JOIN votes v          ON v.postid      = p.id
    LEFT JOIN postlinks pl     ON pl.postid     = p.id
    LEFT JOIN postlinks pl2    ON pl2.relatedpostid = p.id
    LEFT JOIN tags t           ON t.excerptpostid = p.id
    GROUP BY
        p.id,
        p.posttypeid,
        p.creationdate,
        p.score,
        p.viewcount,
        p.owneruserid,
        p.answercount,
        p.commentcount,
        p.favoritecount,
        p.lasteditoruserid
)
SELECT
    post_id,
    posttypeid,
    creationdate,
    post_score,
    viewcount,
    owneruserid,
    answercount,
    commentcount,
    favoritecount,
    lasteditoruserid,
    comment_cnt,
    comment_score_sum,
    vote_cnt,
    upvote_cnt,
    downvote_cnt,
    outlink_cnt,
    inlink_cnt,
    tag_popularity,
    -- composite metric that weights various activity signals
    (post_score * 2
     + comment_score_sum
     + upvote_cnt * 3
     - downvote_cnt * 2
     + outlink_cnt
     + inlink_cnt
     + tag_popularity * 0.5) AS composite_score
FROM post_metrics
WHERE posttypeid = 1   -- focus on question posts (posttypeid = 1)
ORDER BY composite_score DESC
LIMIT 10

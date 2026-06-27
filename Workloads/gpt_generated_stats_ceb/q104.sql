WITH related_post_stats AS (
    SELECT
        pl.postid AS source_post_id,
        COUNT(*) AS related_post_cnt,
        AVG(rp.score) AS avg_related_score,
        SUM(CASE WHEN pl.linktypeid = 1 THEN 1 ELSE 0 END) AS linktype1_cnt,
        SUM(CASE WHEN pl.linktypeid = 2 THEN 1 ELSE 0 END) AS linktype2_cnt
    FROM postlinks pl
    JOIN posts rp ON rp.id = pl.relatedpostid
    GROUP BY pl.postid
)
SELECT
    p.id,
    p.posttypeid,
    p.creationdate,
    p.score,
    p.viewcount,
    p.answercount,
    p.commentcount,
    p.favoritecount,
    COALESCE(rps.related_post_cnt, 0) AS related_post_cnt,
    COALESCE(rps.avg_related_score, 0) AS avg_related_score,
    COALESCE(rps.linktype1_cnt, 0) AS linktype1_cnt,
    COALESCE(rps.linktype2_cnt, 0) AS linktype2_cnt,
    COALESCE(t.count, 0) AS tag_excerpt_count,
    ROW_NUMBER() OVER (ORDER BY COALESCE(rps.related_post_cnt, 0) DESC, p.id) AS rank_by_related_posts
FROM posts p
LEFT JOIN related_post_stats rps ON rps.source_post_id = p.id
LEFT JOIN tags t ON t.excerptpostid = p.id
ORDER BY rank_by_related_posts
LIMIT 100

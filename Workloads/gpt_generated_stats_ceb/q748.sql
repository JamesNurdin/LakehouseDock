WITH tag_posts AS (
    SELECT
        t.id AS tag_id,
        t.excerptpostid AS tag_post_id,
        p.id AS post_id,
        p.score AS post_score,
        p.owneruserid,
        p.creationdate
    FROM tags t
    JOIN posts p ON t.excerptpostid = p.id
),

source_links AS (
    SELECT
        pl.postid AS source_post_id,
        COUNT(*) AS source_link_cnt,
        COUNT(DISTINCT pl.relatedpostid) AS distinct_target_cnt,
        AVG(p_target.score) AS avg_target_score,
        AVG(p_target.answercount) AS avg_target_answercount,
        SUM(pl.linktypeid) AS sum_linktypeid
    FROM postlinks pl
    JOIN posts p_target ON pl.relatedpostid = p_target.id
    GROUP BY pl.postid
),

target_links AS (
    SELECT
        pl.relatedpostid AS target_post_id,
        COUNT(*) AS target_link_cnt,
        COUNT(DISTINCT pl.postid) AS distinct_source_cnt,
        AVG(p_source.score) AS avg_source_score,
        AVG(p_source.answercount) AS avg_source_answercount,
        SUM(pl.linktypeid) AS sum_linktypeid_target
    FROM postlinks pl
    JOIN posts p_source ON pl.postid = p_source.id
    GROUP BY pl.relatedpostid
)

SELECT
    tp.tag_id,
    tp.tag_post_id,
    tp.post_score AS tag_post_score,
    COALESCE(sl.source_link_cnt, 0) AS source_link_count,
    COALESCE(sl.distinct_target_cnt, 0) AS distinct_target_posts,
    COALESCE(sl.avg_target_score, 0) AS avg_target_score,
    COALESCE(sl.avg_target_answercount, 0) AS avg_target_answercount,
    COALESCE(tl.target_link_cnt, 0) AS target_link_count,
    COALESCE(tl.distinct_source_cnt, 0) AS distinct_source_posts,
    COALESCE(tl.avg_source_score, 0) AS avg_source_score,
    COALESCE(tl.avg_source_answercount, 0) AS avg_source_answercount
FROM tag_posts tp
LEFT JOIN source_links sl ON sl.source_post_id = tp.post_id
LEFT JOIN target_links tl ON tl.target_post_id = tp.post_id
ORDER BY tp.tag_id

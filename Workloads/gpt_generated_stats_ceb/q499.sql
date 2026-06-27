WITH link_stats AS (
    SELECT
        pl.linktypeid,
        pl.id AS link_id,
        src.id AS src_post_id,
        src.posttypeid AS src_posttypeid,
        src.creationdate AS src_creationdate,
        src.score AS src_score,
        src.viewcount AS src_viewcount,
        src.owneruserid AS src_owneruserid,
        src.answercount AS src_answercount,
        src.commentcount AS src_commentcount,
        src.favoritecount AS src_favoritecount,
        src.lasteditoruserid AS src_lasteditoruserid,
        tgt.id AS tgt_post_id,
        tgt.posttypeid AS tgt_posttypeid,
        tgt.creationdate AS tgt_creationdate,
        tgt.score AS tgt_score,
        tgt.viewcount AS tgt_viewcount,
        tgt.owneruserid AS tgt_owneruserid,
        tgt.answercount AS tgt_answercount,
        tgt.commentcount AS tgt_commentcount,
        tgt.favoritecount AS tgt_favoritecount,
        tgt.lasteditoruserid AS tgt_lasteditoruserid
    FROM postlinks pl
    JOIN posts src ON pl.postid = src.id
    JOIN posts tgt ON pl.relatedpostid = tgt.id
)
SELECT
    linktypeid,
    COUNT(*) AS total_links,
    AVG(src_score) AS avg_source_score,
    AVG(tgt_score) AS avg_target_score,
    SUM(src_viewcount) AS total_source_views,
    SUM(tgt_viewcount) AS total_target_views,
    COUNT(DISTINCT src_owneruserid) AS distinct_source_owners,
    COUNT(DISTINCT tgt_owneruserid) AS distinct_target_owners
FROM link_stats
GROUP BY linktypeid
ORDER BY total_links DESC

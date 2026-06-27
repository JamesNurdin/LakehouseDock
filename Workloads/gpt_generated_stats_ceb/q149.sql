SELECT
    src.id AS post_id,
    src.posttypeid,
    src.creationdate,
    src.owneruserid,
    COUNT(pl.id) AS outgoing_link_count,
    SUM(tgt.score) AS total_score_of_linked_posts,
    AVG(tgt.score) AS avg_score_of_linked_posts,
    AVG(tgt.score - src.score) AS avg_score_difference,
    SUM(CASE WHEN pl.linktypeid = 1 THEN 1 ELSE 0 END) AS linktype_1_count,
    SUM(CASE WHEN pl.linktypeid = 2 THEN 1 ELSE 0 END) AS linktype_2_count
FROM postlinks pl
JOIN posts src
    ON pl.postid = src.id
JOIN posts tgt
    ON pl.relatedpostid = tgt.id
GROUP BY
    src.id,
    src.posttypeid,
    src.creationdate,
    src.owneruserid
ORDER BY outgoing_link_count DESC
LIMIT 100

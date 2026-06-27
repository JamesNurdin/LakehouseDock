/*
  Analytical query: For each link type and pair of post types (source → related),
  count the number of links and compute aggregate metrics of the linked posts.
*/
WITH linked_posts AS (
    SELECT
        pl.id AS link_id,
        pl.linktypeid,
        pl.postid AS source_post_id,
        pl.relatedpostid AS related_post_id,
        p1.posttypeid AS source_posttypeid,
        p1.creationdate AS source_creationdate,
        p1.score AS source_score,
        p1.viewcount AS source_viewcount,
        p1.answercount AS source_answercount,
        p2.posttypeid AS related_posttypeid,
        p2.creationdate AS related_creationdate,
        p2.score AS related_score,
        p2.viewcount AS related_viewcount,
        p2.answercount AS related_answercount
    FROM postlinks pl
    JOIN posts p1
        ON pl.postid = p1.id
    JOIN posts p2
        ON pl.relatedpostid = p2.id
)
SELECT
    linktypeid,
    source_posttypeid,
    related_posttypeid,
    COUNT(*) AS link_count,
    AVG(source_score) AS avg_source_score,
    AVG(related_score) AS avg_related_score,
    SUM(source_viewcount) AS total_source_viewcount,
    SUM(related_viewcount) AS total_related_viewcount,
    MAX(source_answercount) AS max_source_answercount,
    MAX(related_answercount) AS max_related_answercount
FROM linked_posts
GROUP BY
    linktypeid,
    source_posttypeid,
    related_posttypeid
ORDER BY link_count DESC
LIMIT 100

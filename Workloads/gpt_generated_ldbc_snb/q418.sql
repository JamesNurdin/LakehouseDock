/*
  Analytical query: activity per tag class across posts and comments.
  For each tag class we compute:
    • Number of posts and total post length
    • Number of comments, total comment length, and average comment length
    • Distinct creators of posts and comments
    • Total and average likes on comments
  Results are ordered by combined content length and limited to the top 10 tag classes.
*/
WITH post_agg AS (
    SELECT
        tc.id   AS tag_class_id,
        tc.name AS tag_class_name,
        COUNT(DISTINCT p.id)                     AS post_count,
        SUM(p.length)                            AS total_post_length,
        COUNT(DISTINCT p.creator_person_id)      AS distinct_post_creators
    FROM post_has_tag_tag pht
    JOIN tag t
      ON pht.tag_id = t.id
    JOIN tag_class tc
      ON t.type_tag_class_id = tc.id
    JOIN post p
      ON pht.post_id = p.id
    GROUP BY tc.id, tc.name
),
comment_agg AS (
    SELECT
        tc.id   AS tag_class_id,
        tc.name AS tag_class_name,
        COUNT(DISTINCT c.id)                     AS comment_count,
        SUM(c.length)                            AS total_comment_length,
        COUNT(DISTINCT c.creator_person_id)      AS distinct_comment_creators,
        SUM(COALESCE(lc.like_cnt, 0))            AS total_comment_likes,
        AVG(COALESCE(lc.like_cnt, 0))            AS avg_likes_per_comment
    FROM comment_has_tag_tag cht
    JOIN tag t
      ON cht.tag_id = t.id
    JOIN tag_class tc
      ON t.type_tag_class_id = tc.id
    JOIN "comment" c
      ON cht.comment_id = c.id
    LEFT JOIN (
        SELECT
            plc.comment_id,
            COUNT(*) AS like_cnt
        FROM person_likes_comment plc
        GROUP BY plc.comment_id
    ) lc
      ON c.id = lc.comment_id
    GROUP BY tc.id, tc.name
)
SELECT
    COALESCE(p.tag_class_id, c.tag_class_id)   AS tag_class_id,
    COALESCE(p.tag_class_name, c.tag_class_name) AS tag_class_name,
    COALESCE(p.post_count, 0)                 AS post_count,
    COALESCE(c.comment_count, 0)              AS comment_count,
    COALESCE(p.total_post_length, 0)          AS total_post_length,
    COALESCE(c.total_comment_length, 0)       AS total_comment_length,
    COALESCE(p.distinct_post_creators, 0)     AS distinct_post_creators,
    COALESCE(c.distinct_comment_creators, 0)  AS distinct_comment_creators,
    COALESCE(c.total_comment_likes, 0)        AS total_comment_likes,
    COALESCE(c.avg_likes_per_comment, 0)      AS avg_likes_per_comment
FROM post_agg p
FULL OUTER JOIN comment_agg c
  ON p.tag_class_id = c.tag_class_id
ORDER BY (COALESCE(p.total_post_length, 0) + COALESCE(c.total_comment_length, 0)) DESC
LIMIT 10

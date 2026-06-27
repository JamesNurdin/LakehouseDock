WITH source_posts AS (
    SELECT id,
           score,
           viewcount
    FROM posts
),
target_posts AS (
    SELECT id,
           score AS target_score,
           viewcount AS target_viewcount
    FROM posts
),
post_tags AS (
    SELECT excerptpostid,
           COUNT(*) AS tag_count
    FROM tags
    GROUP BY excerptpostid
)
SELECT pl.linktypeid,
       COUNT(*) AS link_count,
       COUNT(DISTINCT sp.id) AS distinct_source_posts,
       COUNT(DISTINCT tp.id) AS distinct_target_posts,
       AVG(sp.score) AS avg_source_score,
       AVG(tp.target_score) AS avg_target_score,
       SUM(sp.viewcount) AS sum_source_viewcount,
       SUM(tp.target_viewcount) AS sum_target_viewcount,
       COALESCE(SUM(pt.tag_count), 0) AS total_tags_on_source_posts,
       AVG(COALESCE(pt.tag_count, 0)) AS avg_tags_per_source_post
FROM postlinks pl
JOIN source_posts sp ON pl.postid = sp.id
JOIN target_posts tp ON pl.relatedpostid = tp.id
LEFT JOIN post_tags pt ON sp.id = pt.excerptpostid
GROUP BY pl.linktypeid
ORDER BY link_count DESC

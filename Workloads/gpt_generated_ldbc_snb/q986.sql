/*
  Analytical query: For each country (place) and its parent region, compute
  - total number of comments
  - number of top‑level comments vs. replies
  - average comment length (overall, replies, and parent comments)
  - average length difference between a reply and its parent comment
  - total likes received on those comments and average likes per comment
  Results are ordered by total likes descending.
*/
WITH likes_per_comment AS (
    SELECT
        comment_id,
        COUNT(*) AS like_count
    FROM person_likes_comment
    GROUP BY comment_id
)
SELECT
    country.id   AS country_id,
    country.name AS country_name,
    region.id    AS region_id,
    region.name  AS region_name,
    COUNT(DISTINCT c.id)                                                     AS total_comments,
    COUNT(DISTINCT CASE WHEN c.parent_comment_id IS NULL THEN c.id END)      AS top_level_comments,
    COUNT(DISTINCT CASE WHEN c.parent_comment_id IS NOT NULL THEN c.id END)  AS reply_comments,
    AVG(c.length)                                                            AS avg_comment_length,
    AVG(CASE WHEN c.parent_comment_id IS NOT NULL THEN c.length END)        AS avg_reply_length,
    AVG(CASE WHEN c.parent_comment_id IS NOT NULL THEN pc.length END)       AS avg_parent_length,
    AVG(CASE WHEN c.parent_comment_id IS NOT NULL THEN c.length - pc.length END) AS avg_length_diff_reply_parent,
    SUM(COALESCE(l.like_count, 0))                                           AS total_likes,
    CAST(SUM(COALESCE(l.like_count, 0)) AS double) / COUNT(DISTINCT c.id)    AS avg_likes_per_comment
FROM comment c
LEFT JOIN comment pc
    ON c.parent_comment_id = pc.id
LEFT JOIN likes_per_comment l
    ON c.id = l.comment_id
JOIN place country
    ON c.location_country_id = country.id
LEFT JOIN place region
    ON country.part_of_place_id = region.id
GROUP BY
    country.id,
    country.name,
    region.id,
    region.name
ORDER BY total_likes DESC
LIMIT 20

/*
  Analytical query: For each tag class, compute the number of distinct posts that have at least one tag belonging to that class,
  the total number of likes those posts received, the total number of distinct likers, the number of distinct forums
  containing such posts, and the number of distinct creators of those posts. The result is ordered by total likes
  (descending) and limited to the top 10 tag classes.
*/
WITH post_likes AS (
    SELECT
        p.id AS post_id,
        COUNT(pl.person_id) AS like_count,
        COUNT(DISTINCT pl.person_id) AS distinct_liker_count
    FROM post p
    LEFT JOIN person_likes_post pl
        ON pl.post_id = p.id
    GROUP BY p.id
),
post_tag_classes AS (
    SELECT DISTINCT
        pht.post_id,
        tc.id   AS tag_class_id,
        tc.name AS tag_class_name
    FROM post_has_tag_tag pht
    JOIN tag t
        ON pht.tag_id = t.id
    JOIN tag_class tc
        ON t.type_tag_class_id = tc.id
)
SELECT
    ptc.tag_class_id,
    ptc.tag_class_name,
    COUNT(DISTINCT ptc.post_id)               AS post_count,
    SUM(pl.like_count)                        AS total_likes,
    SUM(pl.distinct_liker_count)              AS total_distinct_likers,
    COUNT(DISTINCT f.id)                      AS forum_count,
    COUNT(DISTINCT p.creator_person_id)       AS distinct_creator_count
FROM post_tag_classes ptc
JOIN post_likes pl
    ON pl.post_id = ptc.post_id
JOIN post p
    ON p.id = ptc.post_id
JOIN forum f
    ON p.container_forum_id = f.id
GROUP BY ptc.tag_class_id, ptc.tag_class_name
ORDER BY total_likes DESC
LIMIT 10

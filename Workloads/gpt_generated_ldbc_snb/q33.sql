/*
   Analytical query: for each tag class (and its parent class, if any) report
   • the number of distinct tags belonging to the class
   • how many distinct comments, forums and posts are tagged with any tag of the class
   • the total usage (sum of the three usage counts)
   Results are ordered by total usage and limited to the top‑10 classes.
*/
WITH tag_class_hierarchy AS (
    SELECT
        tc.id   AS tag_class_id,
        tc.name AS tag_class_name,
        pc.name AS parent_tag_class_name
    FROM tag_class tc
    LEFT JOIN tag_class pc
        ON tc.subclass_of_tag_class_id = pc.id
),
tag_counts AS (
    SELECT
        t.type_tag_class_id AS tag_class_id,
        COUNT(*)            AS tag_cnt
    FROM tag t
    GROUP BY t.type_tag_class_id
),
usage_counts AS (
    SELECT
        t.type_tag_class_id                     AS tag_class_id,
        COUNT(DISTINCT cht.comment_id)          AS comment_cnt,
        COUNT(DISTINCT fht.forum_id)            AS forum_cnt,
        COUNT(DISTINCT pht.post_id)             AS post_cnt
    FROM tag t
    LEFT JOIN comment_has_tag_tag cht ON cht.tag_id = t.id
    LEFT JOIN forum_has_tag_tag   fht ON fht.tag_id = t.id
    LEFT JOIN post_has_tag_tag    pht ON pht.tag_id = t.id
    GROUP BY t.type_tag_class_id
)
SELECT
    h.tag_class_name,
    h.parent_tag_class_name,
    COALESCE(tc.tag_cnt, 0)               AS distinct_tag_count,
    COALESCE(u.comment_cnt, 0)            AS comment_usage,
    COALESCE(u.forum_cnt, 0)              AS forum_usage,
    COALESCE(u.post_cnt, 0)               AS post_usage,
    (COALESCE(u.comment_cnt, 0) + COALESCE(u.forum_cnt, 0) + COALESCE(u.post_cnt, 0)) AS total_usage
FROM tag_class_hierarchy h
LEFT JOIN tag_counts   tc ON tc.tag_class_id = h.tag_class_id
LEFT JOIN usage_counts u  ON u.tag_class_id = h.tag_class_id
ORDER BY total_usage DESC
LIMIT 10

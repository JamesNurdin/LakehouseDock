WITH post_tag_stats AS (
    SELECT
        tc.id AS tag_class_id,
        tc.name AS tag_class_name,
        COUNT(DISTINCT p.id) AS post_cnt,
        AVG(p.length) AS avg_post_length
    FROM post_has_tag_tag pt
    JOIN post p ON pt.post_id = p.id
    JOIN tag t ON pt.tag_id = t.id
    JOIN tag_class tc ON t.type_tag_class_id = tc.id
    GROUP BY tc.id, tc.name
),
comment_tag_stats AS (
    SELECT
        tc.id AS tag_class_id,
        COUNT(DISTINCT ct.comment_id) AS comment_cnt
    FROM comment_has_tag_tag ct
    JOIN tag t ON ct.tag_id = t.id
    JOIN tag_class tc ON t.type_tag_class_id = tc.id
    GROUP BY tc.id
),
forum_tag_stats AS (
    SELECT
        tc.id AS tag_class_id,
        COUNT(DISTINCT ft.forum_id) AS forum_cnt
    FROM forum_has_tag_tag ft
    JOIN tag t ON ft.tag_id = t.id
    JOIN tag_class tc ON t.type_tag_class_id = tc.id
    GROUP BY tc.id
),
person_interest_stats AS (
    SELECT
        tc.id AS tag_class_id,
        COUNT(DISTINCT pi.person_id) AS person_cnt
    FROM person_has_interest_tag pi
    JOIN tag t ON pi.tag_id = t.id
    JOIN tag_class tc ON t.type_tag_class_id = tc.id
    GROUP BY tc.id
),
combined_child_stats AS (
    SELECT
        pts.tag_class_id AS child_tag_class_id,
        pts.tag_class_name AS child_tag_class_name,
        child_tc.subclass_of_tag_class_id AS parent_tag_class_id,
        pts.post_cnt,
        pts.avg_post_length,
        COALESCE(cts.comment_cnt, 0) AS comment_cnt,
        COALESCE(fts.forum_cnt, 0) AS forum_cnt,
        COALESCE(pis.person_cnt, 0) AS person_cnt
    FROM post_tag_stats pts
    LEFT JOIN comment_tag_stats cts ON pts.tag_class_id = cts.tag_class_id
    LEFT JOIN forum_tag_stats fts ON pts.tag_class_id = fts.tag_class_id
    LEFT JOIN person_interest_stats pis ON pts.tag_class_id = pis.tag_class_id
    JOIN tag_class child_tc ON pts.tag_class_id = child_tc.id
)
SELECT
    COALESCE(parent_tc.id, child_stats.child_tag_class_id) AS tag_class_id,
    COALESCE(parent_tc.name, child_stats.child_tag_class_name) AS tag_class_name,
    SUM(child_stats.post_cnt) AS total_posts,
    AVG(child_stats.avg_post_length) AS avg_post_length,
    SUM(child_stats.comment_cnt) AS total_comments,
    SUM(child_stats.forum_cnt) AS total_forums,
    SUM(child_stats.person_cnt) AS total_persons,
    (SUM(child_stats.post_cnt) + SUM(child_stats.comment_cnt) + SUM(child_stats.forum_cnt) + SUM(child_stats.person_cnt)) AS total_entities
FROM combined_child_stats child_stats
LEFT JOIN tag_class parent_tc ON child_stats.parent_tag_class_id = parent_tc.id
GROUP BY
    COALESCE(parent_tc.id, child_stats.child_tag_class_id),
    COALESCE(parent_tc.name, child_stats.child_tag_class_name)
ORDER BY total_entities DESC
LIMIT 10

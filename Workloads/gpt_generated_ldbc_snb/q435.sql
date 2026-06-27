WITH tag_class_hierarchy AS (
    SELECT
        tc.id AS tag_class_id,
        tc.name AS tag_class_name,
        COALESCE(parent_tc.id, tc.id) AS top_tag_class_id,
        COALESCE(parent_tc.name, tc.name) AS top_tag_class_name
    FROM tag_class tc
    LEFT JOIN tag_class parent_tc
        ON tc.subclass_of_tag_class_id = parent_tc.id
),
forum_tag_counts AS (
    SELECT
        th.top_tag_class_id,
        th.top_tag_class_name,
        COUNT(DISTINCT fht.forum_id) AS forum_cnt,
        COUNT(DISTINCT fht.tag_id) AS distinct_forum_tags
    FROM forum_has_tag_tag fht
    JOIN tag t
        ON t.id = fht.tag_id
    JOIN tag_class_hierarchy th
        ON th.tag_class_id = t.type_tag_class_id
    GROUP BY th.top_tag_class_id, th.top_tag_class_name
),
post_tag_counts AS (
    SELECT
        th.top_tag_class_id,
        th.top_tag_class_name,
        COUNT(DISTINCT pht.post_id) AS post_cnt,
        COUNT(DISTINCT pht.tag_id) AS distinct_post_tags
    FROM post_has_tag_tag pht
    JOIN tag t
        ON t.id = pht.tag_id
    JOIN tag_class_hierarchy th
        ON th.tag_class_id = t.type_tag_class_id
    GROUP BY th.top_tag_class_id, th.top_tag_class_name
)
SELECT
    COALESCE(ftc.top_tag_class_name, ptc.top_tag_class_name) AS top_tag_class_name,
    COALESCE(forum_cnt, 0) AS forum_count,
    COALESCE(distinct_forum_tags, 0) AS distinct_forum_tags,
    COALESCE(post_cnt, 0) AS post_count,
    COALESCE(distinct_post_tags, 0) AS distinct_post_tags,
    CASE
        WHEN COALESCE(forum_cnt, 0) + COALESCE(post_cnt, 0) = 0 THEN 0
        ELSE (COALESCE(distinct_forum_tags, 0) + COALESCE(distinct_post_tags, 0)) * 1.0
             / (COALESCE(forum_cnt, 0) + COALESCE(post_cnt, 0))
    END AS avg_distinct_tags_per_entity
FROM forum_tag_counts ftc
FULL OUTER JOIN post_tag_counts ptc
    ON ftc.top_tag_class_id = ptc.top_tag_class_id
ORDER BY forum_count DESC, post_count DESC
LIMIT 20

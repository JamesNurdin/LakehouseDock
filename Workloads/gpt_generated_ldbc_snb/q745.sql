WITH comment_stats AS (
    SELECT
        tc.id AS tag_class_id,
        COUNT(DISTINCT c.id) AS comment_cnt,
        AVG(c.length) AS avg_comment_length
    FROM comment c
    JOIN comment_has_tag_tag cht ON cht.comment_id = c.id
    JOIN tag t ON t.id = cht.tag_id
    JOIN tag_class tc ON tc.id = t.type_tag_class_id
    GROUP BY tc.id
),
post_stats AS (
    SELECT
        tc.id AS tag_class_id,
        COUNT(DISTINCT pht.post_id) AS post_cnt
    FROM post_has_tag_tag pht
    JOIN tag t ON t.id = pht.tag_id
    JOIN tag_class tc ON tc.id = t.type_tag_class_id
    GROUP BY tc.id
),
forum_stats AS (
    SELECT
        tc.id AS tag_class_id,
        COUNT(DISTINCT fht.forum_id) AS forum_cnt
    FROM forum_has_tag_tag fht
    JOIN tag t ON t.id = fht.tag_id
    JOIN tag_class tc ON tc.id = t.type_tag_class_id
    GROUP BY tc.id
),
person_stats AS (
    SELECT
        tc.id AS tag_class_id,
        COUNT(DISTINCT pit.person_id) AS person_cnt
    FROM person_has_interest_tag pit
    JOIN tag t ON t.id = pit.tag_id
    JOIN tag_class tc ON tc.id = t.type_tag_class_id
    GROUP BY tc.id
),
reply_pair_stats AS (
    SELECT
        tc.id AS tag_class_id,
        COUNT(*) AS reply_pair_cnt
    FROM comment child
    JOIN comment parent ON child.parent_comment_id = parent.id
    JOIN comment_has_tag_tag ct_child ON ct_child.comment_id = child.id
    JOIN comment_has_tag_tag ct_parent ON ct_parent.comment_id = parent.id
    JOIN tag t_child ON t_child.id = ct_child.tag_id
    JOIN tag t_parent ON t_parent.id = ct_parent.tag_id
    JOIN tag_class tc ON tc.id = t_child.type_tag_class_id
    WHERE t_child.id = t_parent.id
    GROUP BY tc.id
)
SELECT
    tc.name AS tag_class_name,
    COALESCE(cs.comment_cnt, 0) AS comment_count,
    COALESCE(cs.avg_comment_length, 0.0) AS avg_comment_length,
    COALESCE(ps.post_cnt, 0) AS post_count,
    COALESCE(fs.forum_cnt, 0) AS forum_count,
    COALESCE(pis.person_cnt, 0) AS person_count,
    COALESCE(rps.reply_pair_cnt, 0) AS reply_pair_count
FROM tag_class tc
LEFT JOIN comment_stats cs ON cs.tag_class_id = tc.id
LEFT JOIN post_stats ps ON ps.tag_class_id = tc.id
LEFT JOIN forum_stats fs ON fs.tag_class_id = tc.id
LEFT JOIN person_stats pis ON pis.tag_class_id = tc.id
LEFT JOIN reply_pair_stats rps ON rps.tag_class_id = tc.id
ORDER BY tc.name

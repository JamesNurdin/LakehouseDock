WITH
    post_metrics AS (
        SELECT
            tc.id AS tag_class_id,
            COUNT(DISTINCT p.id) AS post_count,
            AVG(p.length) AS avg_post_length
        FROM post_has_tag_tag pht
        JOIN tag t ON pht.tag_id = t.id
        JOIN tag_class tc ON t.type_tag_class_id = tc.id
        JOIN post p ON pht.post_id = p.id
        GROUP BY tc.id
    ),
    comment_metrics AS (
        SELECT
            tc.id AS tag_class_id,
            COUNT(*) AS comment_tag_count
        FROM comment_has_tag_tag cht
        JOIN tag t ON cht.tag_id = t.id
        JOIN tag_class tc ON t.type_tag_class_id = tc.id
        GROUP BY tc.id
    ),
    forum_metrics AS (
        SELECT
            tc.id AS tag_class_id,
            COUNT(*) AS forum_tag_count
        FROM forum_has_tag_tag fht
        JOIN tag t ON fht.tag_id = t.id
        JOIN tag_class tc ON t.type_tag_class_id = tc.id
        GROUP BY tc.id
    ),
    person_metrics AS (
        SELECT
            tc.id AS tag_class_id,
            COUNT(DISTINCT phi.person_id) AS person_interest_count
        FROM person_has_interest_tag phi
        JOIN tag t ON phi.tag_id = t.id
        JOIN tag_class tc ON t.type_tag_class_id = tc.id
        GROUP BY tc.id
    )
SELECT
    tc.id AS tag_class_id,
    tc.name AS tag_class_name,
    pc.id AS parent_tag_class_id,
    pc.name AS parent_tag_class_name,
    COALESCE(pm.post_count, 0) AS post_count,
    COALESCE(pm.avg_post_length, 0) AS avg_post_length,
    COALESCE(cm.comment_tag_count, 0) AS comment_tag_count,
    COALESCE(fm.forum_tag_count, 0) AS forum_tag_count,
    COALESCE(pim.person_interest_count, 0) AS person_interest_count
FROM tag_class tc
LEFT JOIN tag_class pc ON tc.subclass_of_tag_class_id = pc.id
LEFT JOIN post_metrics pm ON tc.id = pm.tag_class_id
LEFT JOIN comment_metrics cm ON tc.id = cm.tag_class_id
LEFT JOIN forum_metrics fm ON tc.id = fm.tag_class_id
LEFT JOIN person_metrics pim ON tc.id = pim.tag_class_id
ORDER BY post_count DESC, comment_tag_count DESC
LIMIT 100

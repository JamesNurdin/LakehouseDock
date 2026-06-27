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
    forum_metrics AS (
        SELECT
            tc.id AS tag_class_id,
            COUNT(DISTINCT f.id) AS forum_count,
            COUNT(DISTINCT mod.id) AS moderator_count
        FROM forum_has_tag_tag fht
        JOIN tag t ON fht.tag_id = t.id
        JOIN tag_class tc ON t.type_tag_class_id = tc.id
        JOIN forum f ON fht.forum_id = f.id
        JOIN person mod ON f.moderator_person_id = mod.id
        GROUP BY tc.id
    ),
    person_interest_metrics AS (
        SELECT
            tc.id AS tag_class_id,
            COUNT(DISTINCT p.id) AS person_interest_count
        FROM person_has_interest_tag phit
        JOIN tag t ON phit.tag_id = t.id
        JOIN tag_class tc ON t.type_tag_class_id = tc.id
        JOIN person p ON phit.person_id = p.id
        GROUP BY tc.id
    ),
    comment_metrics AS (
        SELECT
            tc.id AS tag_class_id,
            COUNT(DISTINCT cht.comment_id) AS comment_count
        FROM comment_has_tag_tag cht
        JOIN tag t ON cht.tag_id = t.id
        JOIN tag_class tc ON t.type_tag_class_id = tc.id
        GROUP BY tc.id
    )
SELECT
    child.id AS tag_class_id,
    child.name AS tag_class_name,
    parent.id AS parent_class_id,
    parent.name AS parent_class_name,
    COALESCE(cm.comment_count, 0) AS comment_count,
    COALESCE(pm.post_count, 0) AS post_count,
    pm.avg_post_length,
    COALESCE(fm.forum_count, 0) AS forum_count,
    COALESCE(fm.moderator_count, 0) AS moderator_count,
    COALESCE(pim.person_interest_count, 0) AS person_interest_count
FROM tag_class child
LEFT JOIN tag_class parent
    ON child.subclass_of_tag_class_id = parent.id
LEFT JOIN comment_metrics cm
    ON child.id = cm.tag_class_id
LEFT JOIN post_metrics pm
    ON child.id = pm.tag_class_id
LEFT JOIN forum_metrics fm
    ON child.id = fm.tag_class_id
LEFT JOIN person_interest_metrics pim
    ON child.id = pim.tag_class_id
ORDER BY post_count DESC, child.name

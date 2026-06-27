WITH
    post_tag_class AS (
        SELECT
            tc.id AS tag_class_id,
            p.id AS post_id,
            p.length AS post_length,
            p.creator_person_id AS creator_id
        FROM tag_class tc
        JOIN tag t ON t.type_tag_class_id = tc.id
        JOIN post_has_tag_tag pht ON pht.tag_id = t.id
        JOIN post p ON p.id = pht.post_id
    ),
    distinct_posts AS (
        SELECT DISTINCT
            tag_class_id,
            post_id,
            post_length,
            creator_id
        FROM post_tag_class
    ),
    post_metrics AS (
        SELECT
            tag_class_id,
            COUNT(DISTINCT post_id) AS post_count,
            AVG(post_length) AS avg_post_length,
            COUNT(DISTINCT creator_id) AS distinct_creator_count
        FROM distinct_posts
        GROUP BY tag_class_id
    ),
    forum_tag_class AS (
        SELECT
            tc.id AS tag_class_id,
            f.id AS forum_id
        FROM tag_class tc
        JOIN tag t ON t.type_tag_class_id = tc.id
        JOIN forum_has_tag_tag fht ON fht.tag_id = t.id
        JOIN forum f ON f.id = fht.forum_id
    ),
    forum_metrics AS (
        SELECT
            tag_class_id,
            COUNT(DISTINCT forum_id) AS forum_count
        FROM forum_tag_class
        GROUP BY tag_class_id
    ),
    person_interest_tag_class AS (
        SELECT
            tc.id AS tag_class_id,
            p.id AS person_id
        FROM tag_class tc
        JOIN tag t ON t.type_tag_class_id = tc.id
        JOIN person_has_interest_tag pit ON pit.tag_id = t.id
        JOIN person p ON p.id = pit.person_id
    ),
    person_interest_metrics AS (
        SELECT
            tag_class_id,
            COUNT(DISTINCT person_id) AS person_interest_count
        FROM person_interest_tag_class
        GROUP BY tag_class_id
    ),
    comment_tag_class AS (
        SELECT
            tc.id AS tag_class_id,
            cht.comment_id AS comment_id
        FROM tag_class tc
        JOIN tag t ON t.type_tag_class_id = tc.id
        JOIN comment_has_tag_tag cht ON cht.tag_id = t.id
    ),
    comment_metrics AS (
        SELECT
            tag_class_id,
            COUNT(DISTINCT comment_id) AS comment_count
        FROM comment_tag_class
        GROUP BY tag_class_id
    )
SELECT
    tc.id AS tag_class_id,
    tc.name AS tag_class_name,
    COALESCE(pm.post_count, 0) AS post_count,
    pm.avg_post_length,
    COALESCE(pm.distinct_creator_count, 0) AS distinct_creator_count,
    COALESCE(fm.forum_count, 0) AS forum_count,
    COALESCE(pim.person_interest_count, 0) AS person_interest_count,
    COALESCE(cm.comment_count, 0) AS comment_count
FROM tag_class tc
LEFT JOIN post_metrics pm ON pm.tag_class_id = tc.id
LEFT JOIN forum_metrics fm ON fm.tag_class_id = tc.id
LEFT JOIN person_interest_metrics pim ON pim.tag_class_id = tc.id
LEFT JOIN comment_metrics cm ON cm.tag_class_id = tc.id
ORDER BY tc.id

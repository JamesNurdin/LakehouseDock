WITH
    forum_tag_stats AS (
        SELECT
            tc.id AS tag_class_id,
            tc.name AS tag_class_name,
            COUNT(*) AS forum_tag_cnt,
            COUNT(DISTINCT fht.forum_id) AS distinct_forums
        FROM forum_has_tag_tag fht
        JOIN tag t ON fht.tag_id = t.id
        JOIN tag_class tc ON t.type_tag_class_id = tc.id
        GROUP BY tc.id, tc.name
    ),
    post_tag_stats AS (
        SELECT
            tc.id AS tag_class_id,
            tc.name AS tag_class_name,
            COUNT(*) AS post_tag_cnt,
            COUNT(DISTINCT p.id) AS distinct_posts,
            COUNT(DISTINCT p.creator_person_id) AS distinct_post_creators,
            AVG(p.length) AS avg_post_length
        FROM post_has_tag_tag pht
        JOIN post p ON pht.post_id = p.id
        JOIN tag t ON pht.tag_id = t.id
        JOIN tag_class tc ON t.type_tag_class_id = tc.id
        GROUP BY tc.id, tc.name
    ),
    comment_tag_stats AS (
        SELECT
            tc.id AS tag_class_id,
            tc.name AS tag_class_name,
            COUNT(*) AS comment_tag_cnt,
            COUNT(DISTINCT c.id) AS distinct_comments,
            COUNT(DISTINCT c.creator_person_id) AS distinct_comment_creators,
            AVG(c.length) AS avg_comment_length
        FROM comment_has_tag_tag cht
        JOIN comment c ON cht.comment_id = c.id
        JOIN tag t ON cht.tag_id = t.id
        JOIN tag_class tc ON t.type_tag_class_id = tc.id
        GROUP BY tc.id, tc.name
    ),
    interest_tag_stats AS (
        SELECT
            tc.id AS tag_class_id,
            tc.name AS tag_class_name,
            COUNT(*) AS interest_tag_cnt,
            COUNT(DISTINCT pit.person_id) AS distinct_persons
        FROM person_has_interest_tag pit
        JOIN tag t ON pit.tag_id = t.id
        JOIN tag_class tc ON t.type_tag_class_id = tc.id
        GROUP BY tc.id, tc.name
    )
SELECT
    tc.id AS tag_class_id,
    tc.name AS tag_class_name,
    ft.forum_tag_cnt,
    ft.distinct_forums,
    pt.post_tag_cnt,
    pt.distinct_posts,
    pt.distinct_post_creators,
    pt.avg_post_length,
    ct.comment_tag_cnt,
    ct.distinct_comments,
    ct.distinct_comment_creators,
    ct.avg_comment_length,
    it.interest_tag_cnt,
    it.distinct_persons
FROM tag_class tc
LEFT JOIN forum_tag_stats ft ON tc.id = ft.tag_class_id
LEFT JOIN post_tag_stats pt ON tc.id = pt.tag_class_id
LEFT JOIN comment_tag_stats ct ON tc.id = ct.tag_class_id
LEFT JOIN interest_tag_stats it ON tc.id = it.tag_class_id
ORDER BY tc.id

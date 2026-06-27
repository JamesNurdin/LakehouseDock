WITH tags_per_class AS (
    SELECT
        tc.id AS tag_class_id,
        COUNT(DISTINCT t.id) AS tag_count
    FROM tag t
    JOIN tag_class tc ON t.type_tag_class_id = tc.id
    GROUP BY tc.id
),
persons_per_class AS (
    SELECT
        tc.id AS tag_class_id,
        COUNT(DISTINCT p.id) AS person_count
    FROM person_has_interest_tag pht
    JOIN tag t ON pht.tag_id = t.id
    JOIN tag_class tc ON t.type_tag_class_id = tc.id
    JOIN person p ON pht.person_id = p.id
    GROUP BY tc.id
),
comments_per_class AS (
    SELECT
        tc.id AS tag_class_id,
        COUNT(DISTINCT cht.comment_id) AS comment_count
    FROM comment_has_tag_tag cht
    JOIN tag t ON cht.tag_id = t.id
    JOIN tag_class tc ON t.type_tag_class_id = tc.id
    GROUP BY tc.id
),
posts_per_class AS (
    SELECT
        tc.id AS tag_class_id,
        COUNT(DISTINCT pt.post_id) AS post_count
    FROM post_has_tag_tag pt
    JOIN tag t ON pt.tag_id = t.id
    JOIN tag_class tc ON t.type_tag_class_id = tc.id
    GROUP BY tc.id
),
forums_per_class AS (
    SELECT
        tc.id AS tag_class_id,
        COUNT(DISTINCT ft.forum_id) AS forum_count
    FROM forum_has_tag_tag ft
    JOIN tag t ON ft.tag_id = t.id
    JOIN tag_class tc ON t.type_tag_class_id = tc.id
    GROUP BY tc.id
)
SELECT
    tc.id AS tag_class_id,
    tc.name AS tag_class_name,
    tc.subclass_of_tag_class_id AS parent_tag_class_id,
    COALESCE(tpc.tag_count, 0) AS tag_count,
    COALESCE(ppc.person_count, 0) AS person_count,
    COALESCE(cc.comment_count, 0) AS comment_count,
    COALESCE(poc.post_count, 0) AS post_count,
    COALESCE(foc.forum_count, 0) AS forum_count
FROM tag_class tc
LEFT JOIN tags_per_class tpc ON tc.id = tpc.tag_class_id
LEFT JOIN persons_per_class ppc ON tc.id = ppc.tag_class_id
LEFT JOIN comments_per_class cc ON tc.id = cc.tag_class_id
LEFT JOIN posts_per_class poc ON tc.id = poc.tag_class_id
LEFT JOIN forums_per_class foc ON tc.id = foc.tag_class_id
ORDER BY tc.id

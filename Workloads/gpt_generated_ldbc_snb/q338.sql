WITH comment_tag_agg AS (
    SELECT
        t.id AS tag_id,
        t.name AS tag_name,
        tc.name AS tag_class_name,
        COUNT(c.id) AS comment_count,
        COUNT(DISTINCT c.creator_person_id) AS distinct_commenter_count,
        AVG(c.length) AS avg_comment_length
    FROM comment_has_tag_tag ct
    JOIN comment c ON ct.comment_id = c.id
    JOIN tag t ON ct.tag_id = t.id
    LEFT JOIN tag_class tc ON t.type_tag_class_id = tc.id
    GROUP BY t.id, t.name, tc.name
),
post_tag_agg AS (
    SELECT
        t.id AS tag_id,
        COUNT(pht.post_id) AS post_count
    FROM post_has_tag_tag pht
    JOIN tag t ON pht.tag_id = t.id
    GROUP BY t.id
),
interest_tag_agg AS (
    SELECT
        t.id AS tag_id,
        COUNT(DISTINCT pit.person_id) AS interested_person_count
    FROM person_has_interest_tag pit
    JOIN tag t ON pit.tag_id = t.id
    GROUP BY t.id
),
forum_tag_agg AS (
    SELECT
        t.id AS tag_id,
        COUNT(DISTINCT f.id) AS forum_count
    FROM forum_has_tag_tag ft
    JOIN forum f ON ft.forum_id = f.id
    JOIN tag t ON ft.tag_id = t.id
    GROUP BY t.id
)
SELECT
    ct.tag_id,
    ct.tag_name,
    ct.tag_class_name,
    ct.comment_count,
    ct.distinct_commenter_count,
    ct.avg_comment_length,
    COALESCE(pt.post_count, 0) AS post_count,
    COALESCE(it.interested_person_count, 0) AS interested_person_count,
    COALESCE(ft.forum_count, 0) AS forum_count
FROM comment_tag_agg ct
LEFT JOIN post_tag_agg pt ON ct.tag_id = pt.tag_id
LEFT JOIN interest_tag_agg it ON ct.tag_id = it.tag_id
LEFT JOIN forum_tag_agg ft ON ct.tag_id = ft.tag_id
ORDER BY ct.comment_count DESC
LIMIT 100

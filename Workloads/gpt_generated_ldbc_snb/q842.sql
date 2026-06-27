WITH tag_class_info AS (
    SELECT
        t.id AS tag_id,
        tc.name AS tag_class_name
    FROM tag t
    JOIN tag_class tc ON t.type_tag_class_id = tc.id
),
post_tag_stats AS (
    SELECT
        t.id AS tag_id,
        COUNT(DISTINCT p.id) AS post_count,
        SUM(p.length) AS total_post_length,
        COUNT(DISTINCT plp.person_id) AS distinct_likers
    FROM post_has_tag_tag pht
    JOIN post p ON pht.post_id = p.id
    JOIN tag t ON pht.tag_id = t.id
    LEFT JOIN person_likes_post plp ON plp.post_id = p.id
    GROUP BY t.id
),
comment_tag_stats AS (
    SELECT
        t.id AS tag_id,
        COUNT(DISTINCT cht.comment_id) AS comment_count
    FROM comment_has_tag_tag cht
    JOIN tag t ON cht.tag_id = t.id
    GROUP BY t.id
),
forum_tag_stats AS (
    SELECT
        t.id AS tag_id,
        COUNT(DISTINCT f.id) AS forum_count
    FROM forum_has_tag_tag fht
    JOIN forum f ON fht.forum_id = f.id
    JOIN tag t ON fht.tag_id = t.id
    GROUP BY t.id
),
person_interest_stats AS (
    SELECT
        t.id AS tag_id,
        COUNT(DISTINCT pit.person_id) AS interested_person_count
    FROM person_has_interest_tag pit
    JOIN tag t ON pit.tag_id = t.id
    GROUP BY t.id
)
SELECT
    t.id,
    t.name,
    COALESCE(tci.tag_class_name, '') AS tag_class_name,
    COALESCE(pt.post_count, 0) AS post_count,
    COALESCE(pt.total_post_length, 0) AS total_post_length,
    COALESCE(pt.distinct_likers, 0) AS distinct_likers,
    COALESCE(ct.comment_count, 0) AS comment_count,
    COALESCE(ft.forum_count, 0) AS forum_count,
    COALESCE(it.interested_person_count, 0) AS interested_person_count
FROM tag t
LEFT JOIN tag_class_info tci ON t.id = tci.tag_id
LEFT JOIN post_tag_stats pt ON t.id = pt.tag_id
LEFT JOIN comment_tag_stats ct ON t.id = ct.tag_id
LEFT JOIN forum_tag_stats ft ON t.id = ft.tag_id
LEFT JOIN person_interest_stats it ON t.id = it.tag_id
ORDER BY post_count DESC
LIMIT 10

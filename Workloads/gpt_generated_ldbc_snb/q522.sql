WITH post_likes AS (
    SELECT
        t.id AS tag_id,
        t.name AS tag_name,
        tc.name AS tag_class_name,
        COUNT(pl.person_id) AS post_like_count,
        COUNT(DISTINCT p.creator_person_id) AS post_creator_count
    FROM tag t
    JOIN tag_class tc ON t.type_tag_class_id = tc.id
    JOIN post_has_tag_tag pht ON pht.tag_id = t.id
    JOIN post p ON p.id = pht.post_id
    LEFT JOIN person_likes_post pl ON pl.post_id = p.id
    GROUP BY t.id, t.name, tc.name
),
comment_likes AS (
    SELECT
        t.id AS tag_id,
        t.name AS tag_name,
        tc.name AS tag_class_name,
        COUNT(cl.person_id) AS comment_like_count,
        COUNT(DISTINCT c.creator_person_id) AS comment_creator_count
    FROM tag t
    JOIN tag_class tc ON t.type_tag_class_id = tc.id
    JOIN comment_has_tag_tag cht ON cht.tag_id = t.id
    JOIN comment c ON c.id = cht.comment_id
    LEFT JOIN person_likes_comment cl ON cl.comment_id = c.id
    GROUP BY t.id, t.name, tc.name
)
SELECT
    tag_id,
    tag_name,
    tag_class_name,
    total_like_count,
    total_creator_count,
    row_number() OVER (ORDER BY total_like_count DESC) AS tag_rank
FROM (
    SELECT
        COALESCE(p.tag_id, c.tag_id) AS tag_id,
        COALESCE(p.tag_name, c.tag_name) AS tag_name,
        COALESCE(p.tag_class_name, c.tag_class_name) AS tag_class_name,
        COALESCE(p.post_like_count, 0) + COALESCE(c.comment_like_count, 0) AS total_like_count,
        COALESCE(p.post_creator_count, 0) + COALESCE(c.comment_creator_count, 0) AS total_creator_count
    FROM post_likes p
    FULL OUTER JOIN comment_likes c ON c.tag_id = p.tag_id
) t
ORDER BY total_like_count DESC
LIMIT 10

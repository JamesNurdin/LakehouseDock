WITH post_tags AS (
    SELECT
        p.id AS post_id,
        p.length AS post_length,
        t.id AS tag_id,
        tc.id AS tag_class_id,
        tc.name AS tag_class_name
    FROM post p
    JOIN post_has_tag_tag pht
        ON p.id = pht.post_id
    JOIN tag t
        ON pht.tag_id = t.id
    JOIN tag_class tc
        ON t.type_tag_class_id = tc.id
),
post_likes AS (
    SELECT
        pl.post_id,
        COUNT(DISTINCT pl.person_id) AS like_count
    FROM person_likes_post pl
    GROUP BY pl.post_id
),
post_comments AS (
    SELECT
        c.parent_post_id AS post_id,
        COUNT(*) AS comment_count
    FROM comment c
    WHERE c.parent_post_id IS NOT NULL
    GROUP BY c.parent_post_id
)
SELECT
    pt.tag_class_name,
    COUNT(DISTINCT pt.post_id) AS post_count,
    SUM(COALESCE(pl.like_count, 0)) AS total_likes,
    SUM(COALESCE(pc.comment_count, 0)) AS total_comments,
    AVG(pt.post_length) AS avg_post_length
FROM post_tags pt
LEFT JOIN post_likes pl
    ON pt.post_id = pl.post_id
LEFT JOIN post_comments pc
    ON pt.post_id = pc.post_id
GROUP BY pt.tag_class_name
ORDER BY total_likes DESC
LIMIT 10

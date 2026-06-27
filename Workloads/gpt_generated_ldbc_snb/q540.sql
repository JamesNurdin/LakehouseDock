WITH comment_counts AS (
    SELECT
        t.id AS tag_id,
        COUNT(*) AS comment_cnt,
        MIN(c.creation_date) AS comment_min_date,
        MAX(c.creation_date) AS comment_max_date
    FROM comment_has_tag_tag c
    JOIN tag t ON c.tag_id = t.id
    GROUP BY t.id
),
forum_counts AS (
    SELECT
        t.id AS tag_id,
        COUNT(*) AS forum_cnt,
        MIN(f.creation_date) AS forum_min_date,
        MAX(f.creation_date) AS forum_max_date
    FROM forum_has_tag_tag f
    JOIN tag t ON f.tag_id = t.id
    GROUP BY t.id
),
post_counts AS (
    SELECT
        t.id AS tag_id,
        COUNT(*) AS post_cnt,
        MIN(p.creation_date) AS post_min_date,
        MAX(p.creation_date) AS post_max_date
    FROM post_has_tag_tag p
    JOIN tag t ON p.tag_id = t.id
    GROUP BY t.id
)
SELECT
    tag_id,
    tag_name,
    type_tag_class_id,
    comment_cnt,
    forum_cnt,
    post_cnt,
    total_assignments,
    comment_min_date,
    comment_max_date,
    forum_min_date,
    forum_max_date,
    post_min_date,
    post_max_date,
    tag_rank
FROM (
    SELECT
        t.id AS tag_id,
        t.name AS tag_name,
        t.type_tag_class_id,
        COALESCE(cc.comment_cnt, 0) AS comment_cnt,
        COALESCE(fc.forum_cnt, 0) AS forum_cnt,
        COALESCE(pc.post_cnt, 0) AS post_cnt,
        (COALESCE(cc.comment_cnt, 0) + COALESCE(fc.forum_cnt, 0) + COALESCE(pc.post_cnt, 0)) AS total_assignments,
        cc.comment_min_date,
        cc.comment_max_date,
        fc.forum_min_date,
        fc.forum_max_date,
        pc.post_min_date,
        pc.post_max_date,
        row_number() OVER (ORDER BY (COALESCE(cc.comment_cnt, 0) + COALESCE(fc.forum_cnt, 0) + COALESCE(pc.post_cnt, 0)) DESC) AS tag_rank
    FROM tag t
    LEFT JOIN comment_counts cc ON t.id = cc.tag_id
    LEFT JOIN forum_counts fc ON t.id = fc.tag_id
    LEFT JOIN post_counts pc ON t.id = pc.tag_id
    WHERE COALESCE(cc.comment_cnt, 0) + COALESCE(fc.forum_cnt, 0) + COALESCE(pc.post_cnt, 0) > 0
) AS ranked_tags
WHERE tag_rank <= 50
ORDER BY total_assignments DESC

WITH forum_metrics AS (
    SELECT
        f.id AS forum_id,
        f.title AS forum_title,
        COUNT(DISTINCT p.id) AS post_count,
        COUNT(DISTINCT c.id) AS comment_count,
        AVG(c.length) AS avg_comment_length
    FROM forum f
    LEFT JOIN post p
        ON p.container_forum_id = f.id
    LEFT JOIN comment c
        ON c.parent_post_id = p.id
    GROUP BY f.id, f.title
),
member_counts AS (
    SELECT
        fm.forum_id,
        COUNT(DISTINCT fm.person_id) AS member_count
    FROM forum_has_member_person fm
    GROUP BY fm.forum_id
),
forum_tag_counts AS (
    SELECT
        ft.forum_id,
        COUNT(DISTINCT ft.tag_id) AS forum_tag_count
    FROM forum_has_tag_tag ft
    GROUP BY ft.forum_id
),
comment_tag_counts AS (
    SELECT
        f.id AS forum_id,
        COUNT(DISTINCT ct.tag_id) AS comment_tag_count
    FROM forum f
    LEFT JOIN post p
        ON p.container_forum_id = f.id
    LEFT JOIN comment c
        ON c.parent_post_id = p.id
    LEFT JOIN comment_has_tag_tag ct
        ON ct.comment_id = c.id
    GROUP BY f.id
)
SELECT
    fm.forum_id,
    fm.forum_title,
    fm.post_count,
    fm.comment_count,
    fm.avg_comment_length,
    mc.member_count,
    ftc.forum_tag_count,
    ctc.comment_tag_count,
    (fm.comment_count * 1.0 / NULLIF(fm.post_count, 0)) AS comments_per_post_ratio
FROM forum_metrics fm
LEFT JOIN member_counts mc
    ON mc.forum_id = fm.forum_id
LEFT JOIN forum_tag_counts ftc
    ON ftc.forum_id = fm.forum_id
LEFT JOIN comment_tag_counts ctc
    ON ctc.forum_id = fm.forum_id
ORDER BY fm.post_count DESC
LIMIT 100

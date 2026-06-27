WITH forum_posts AS (
    SELECT
        f.id AS forum_id,
        COUNT(DISTINCT p.id) AS post_count
    FROM forum AS f
    JOIN post AS p
        ON p.container_forum_id = f.id
    GROUP BY f.id
),
forum_comments AS (
    SELECT
        f.id AS forum_id,
        COUNT(DISTINCT c.id) AS comment_count,
        SUM(c.length) AS total_comment_length,
        AVG(c.length) AS avg_comment_length
    FROM forum AS f
    JOIN post AS p
        ON p.container_forum_id = f.id
    JOIN comment AS c
        ON c.parent_post_id = p.id
    GROUP BY f.id
),
forum_members AS (
    SELECT
        f.id AS forum_id,
        COUNT(DISTINCT fm.person_id) AS member_count
    FROM forum AS f
    JOIN forum_has_member_person AS fm
        ON fm.forum_id = f.id
    GROUP BY f.id
),
forum_member_tags AS (
    SELECT
        f.id AS forum_id,
        i.tag_id,
        COUNT(DISTINCT per.id) AS tag_member_count
    FROM forum AS f
    JOIN forum_has_member_person AS fm
        ON fm.forum_id = f.id
    JOIN person AS per
        ON per.id = fm.person_id
    JOIN person_has_interest_tag AS i
        ON i.person_id = per.id
    GROUP BY f.id, i.tag_id
),
forum_top_tag AS (
    SELECT
        forum_id,
        tag_id AS top_tag_id,
        tag_member_count AS top_tag_member_count,
        ROW_NUMBER() OVER (PARTITION BY forum_id ORDER BY tag_member_count DESC) AS rn
    FROM forum_member_tags
)
SELECT
    f.id AS forum_id,
    f.title AS forum_title,
    COALESCE(fp.post_count, 0) AS post_count,
    COALESCE(fc.comment_count, 0) AS comment_count,
    COALESCE(fc.total_comment_length, 0) AS total_comment_length,
    COALESCE(fc.avg_comment_length, 0) AS avg_comment_length,
    COALESCE(fm.member_count, 0) AS member_count,
    ft.top_tag_id,
    ft.top_tag_member_count
FROM forum AS f
LEFT JOIN forum_posts AS fp
    ON fp.forum_id = f.id
LEFT JOIN forum_comments AS fc
    ON fc.forum_id = f.id
LEFT JOIN forum_members AS fm
    ON fm.forum_id = f.id
LEFT JOIN forum_top_tag AS ft
    ON ft.forum_id = f.id AND ft.rn = 1
ORDER BY COALESCE(fc.total_comment_length, 0) DESC
LIMIT 10

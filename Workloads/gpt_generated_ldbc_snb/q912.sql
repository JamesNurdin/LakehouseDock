WITH forum_posts AS (
    SELECT
        f.id AS forum_id,
        COUNT(p.id) AS post_count,
        SUM(p.length) AS total_length
    FROM forum f
    LEFT JOIN post p
        ON p.container_forum_id = f.id
    GROUP BY f.id
),
forum_members AS (
    SELECT
        fm.forum_id,
        COUNT(DISTINCT fm.person_id) AS member_count
    FROM forum_has_member_person fm
    GROUP BY fm.forum_id
),
forum_tags AS (
    SELECT
        ft.forum_id,
        COUNT(DISTINCT ft.tag_id) AS tag_count
    FROM forum_has_tag_tag ft
    GROUP BY ft.forum_id
),
forum_moderators AS (
    SELECT
        f.id AS forum_id,
        p.id AS moderator_id,
        p.first_name AS moderator_first_name,
        p.last_name AS moderator_last_name
    FROM forum f
    LEFT JOIN person p
        ON f.moderator_person_id = p.id
)
SELECT
    f.id AS forum_id,
    f.title,
    f.creation_date AS forum_creation_date,
    COALESCE(fp.post_count, 0) AS post_count,
    CASE
        WHEN COALESCE(fp.post_count, 0) > 0 THEN fp.total_length / fp.post_count
        ELSE NULL
    END AS avg_post_length,
    COALESCE(fm.member_count, 0) AS member_count,
    COALESCE(ft.tag_count, 0) AS tag_count,
    fmtr.moderator_id,
    fmtr.moderator_first_name,
    fmtr.moderator_last_name
FROM forum f
LEFT JOIN forum_posts fp
    ON fp.forum_id = f.id
LEFT JOIN forum_members fm
    ON fm.forum_id = f.id
LEFT JOIN forum_tags ft
    ON ft.forum_id = f.id
LEFT JOIN forum_moderators fmtr
    ON fmtr.forum_id = f.id
ORDER BY post_count DESC
LIMIT 10

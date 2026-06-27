WITH forum_member_counts AS (
    SELECT
        fm.forum_id,
        COUNT(DISTINCT fm.person_id) AS member_count
    FROM forum_has_member_person fm
    GROUP BY fm.forum_id
),
forum_tag_info AS (
    SELECT
        ft.forum_id,
        ft.tag_id,
        f.title AS forum_title,
        f.creation_date AS forum_creation_date,
        COALESCE(mc.member_count, 0) AS member_count
    FROM forum_has_tag_tag ft
    JOIN forum f
        ON ft.forum_id = f.id
    LEFT JOIN forum_member_counts mc
        ON mc.forum_id = ft.forum_id
)
SELECT
    t.id AS tag_id,
    t.name AS tag_name,
    COUNT(DISTINCT fti.forum_id) AS forum_count,
    SUM(fti.member_count) AS total_members,
    AVG(fti.member_count) AS avg_members_per_forum,
    MAX(fti.forum_creation_date) AS latest_forum_creation_date
FROM tag t
JOIN forum_has_tag_tag ft
    ON ft.tag_id = t.id
JOIN forum_tag_info fti
    ON fti.forum_id = ft.forum_id
   AND fti.tag_id = ft.tag_id
GROUP BY t.id, t.name
ORDER BY total_members DESC
LIMIT 10

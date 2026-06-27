WITH forum_base AS (
    SELECT
        f.id AS forum_id,
        f.title,
        f.creation_date AS forum_creation_date,
        mod.id AS moderator_id,
        mod.first_name AS moderator_first_name,
        mod.last_name AS moderator_last_name
    FROM forum f
    LEFT JOIN person mod
        ON f.moderator_person_id = mod.id
),
member_counts AS (
    SELECT
        forum_id,
        COUNT(DISTINCT person_id) AS member_count
    FROM forum_has_member_person
    GROUP BY forum_id
),
tag_counts AS (
    SELECT
        forum_id,
        COUNT(DISTINCT tag_id) AS tag_count
    FROM forum_has_tag_tag
    GROUP BY forum_id
),
forum_tags AS (
    SELECT
        ft.forum_id,
        array_agg(DISTINCT t.name) AS tag_names
    FROM forum_has_tag_tag ft
    JOIN tag t
        ON ft.tag_id = t.id
    GROUP BY ft.forum_id
),
post_stats AS (
    SELECT
        container_forum_id AS forum_id,
        COUNT(*) AS post_count,
        AVG(length) AS avg_post_length
    FROM post
    GROUP BY container_forum_id
)
SELECT
    fb.forum_id,
    fb.title,
    fb.forum_creation_date,
    fb.moderator_first_name,
    fb.moderator_last_name,
    COALESCE(mc.member_count, 0) AS member_count,
    COALESCE(tc.tag_count, 0) AS tag_count,
    ft.tag_names,
    COALESCE(ps.post_count, 0) AS post_count,
    ps.avg_post_length
FROM forum_base fb
LEFT JOIN member_counts mc
    ON fb.forum_id = mc.forum_id
LEFT JOIN tag_counts tc
    ON fb.forum_id = tc.forum_id
LEFT JOIN forum_tags ft
    ON fb.forum_id = ft.forum_id
LEFT JOIN post_stats ps
    ON fb.forum_id = ps.forum_id
ORDER BY post_count DESC
LIMIT 10

WITH forum_stats AS (
    SELECT
        f.id AS forum_id,
        f.title AS forum_title,
        mod.first_name AS moderator_first_name,
        mod.last_name AS moderator_last_name,
        COUNT(DISTINCT p.id) AS post_count,
        AVG(p.length) AS avg_post_length,
        COUNT(DISTINCT c.id) AS comment_count,
        COUNT(DISTINCT fm.person_id) AS member_count
    FROM forum f
    LEFT JOIN person mod
        ON f.moderator_person_id = mod.id
    LEFT JOIN post p
        ON p.container_forum_id = f.id
    LEFT JOIN comment c
        ON c.parent_post_id = p.id
    LEFT JOIN forum_has_member_person fm
        ON fm.forum_id = f.id
    GROUP BY f.id, f.title, mod.first_name, mod.last_name
),
forum_tag_counts AS (
    SELECT
        f.id AS forum_id,
        t.id AS tag_id,
        t.name AS tag_name,
        COUNT(DISTINCT p.id) AS posts_with_tag
    FROM forum f
    JOIN post p
        ON p.container_forum_id = f.id
    JOIN post_has_tag_tag pht
        ON pht.post_id = p.id
    JOIN tag t
        ON pht.tag_id = t.id
    GROUP BY f.id, t.id, t.name
),
forum_top_tags AS (
    SELECT
        forum_id,
        tag_id,
        tag_name,
        posts_with_tag,
        ROW_NUMBER() OVER (PARTITION BY forum_id ORDER BY posts_with_tag DESC) AS tag_rank
    FROM forum_tag_counts
)

SELECT
    fs.forum_id,
    fs.forum_title,
    fs.moderator_first_name,
    fs.moderator_last_name,
    fs.post_count,
    fs.avg_post_length,
    fs.comment_count,
    fs.member_count,
    ft.tag_name,
    ft.posts_with_tag AS tag_post_count
FROM forum_stats fs
LEFT JOIN forum_top_tags ft
    ON ft.forum_id = fs.forum_id
    AND ft.tag_rank <= 5
ORDER BY fs.forum_id, ft.tag_rank

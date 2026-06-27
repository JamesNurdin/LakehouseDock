WITH forum_stats AS (
    SELECT
        f.id AS forum_id,
        f.title,
        f.creation_date AS forum_creation_date,
        mod.first_name AS moderator_first_name,
        mod.last_name AS moderator_last_name,
        COUNT(p.id) AS post_count,
        AVG(p.length) AS avg_post_length,
        COUNT(DISTINCT p.creator_person_id) AS distinct_creators,
        COUNT(DISTINCT ft.tag_id) AS tag_count
    FROM forum f
    LEFT JOIN person mod
        ON f.moderator_person_id = mod.id
    LEFT JOIN post p
        ON p.container_forum_id = f.id
    LEFT JOIN forum_has_tag_tag ft
        ON ft.forum_id = f.id
    GROUP BY f.id, f.title, f.creation_date, mod.first_name, mod.last_name
),
post_lang_counts AS (
    SELECT
        p.container_forum_id AS forum_id,
        p.language,
        COUNT(*) AS lang_post_count
    FROM post p
    GROUP BY p.container_forum_id, p.language
),
top_lang_per_forum AS (
    SELECT
        forum_id,
        language,
        lang_post_count,
        ROW_NUMBER() OVER (PARTITION BY forum_id ORDER BY lang_post_count DESC) AS rn
    FROM post_lang_counts
)
SELECT
    fs.forum_id,
    fs.title,
    fs.forum_creation_date,
    fs.moderator_first_name,
    fs.moderator_last_name,
    fs.post_count,
    fs.avg_post_length,
    fs.distinct_creators,
    fs.tag_count,
    tl.language AS top_language,
    tl.lang_post_count AS top_language_post_count
FROM forum_stats fs
LEFT JOIN top_lang_per_forum tl
    ON fs.forum_id = tl.forum_id AND tl.rn = 1
ORDER BY fs.post_count DESC
LIMIT 10

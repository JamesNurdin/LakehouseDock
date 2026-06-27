WITH member_counts AS (
    SELECT
        forum_id,
        COUNT(DISTINCT person_id) AS member_count
    FROM forum_has_member_person
    GROUP BY forum_id
),
post_stats AS (
    SELECT
        container_forum_id AS forum_id,
        COUNT(*) AS post_count,
        AVG(length) AS avg_post_length,
        approx_percentile(length, 0.5) AS median_post_length,
        SUM(CASE WHEN image_file IS NOT NULL THEN 1 ELSE 0 END) * 100.0 / COUNT(*) AS image_post_pct
    FROM post
    GROUP BY container_forum_id
),
tag_counts AS (
    SELECT
        forum_id,
        COUNT(DISTINCT tag_id) AS tag_count
    FROM forum_has_tag_tag
    GROUP BY forum_id
),
top_tag_per_forum AS (
    SELECT
        f.id AS forum_id,
        tg.name AS tag_name,
        COUNT(*) AS tag_usage,
        ROW_NUMBER() OVER (PARTITION BY f.id ORDER BY COUNT(*) DESC) AS rn
    FROM forum_has_tag_tag ft
    JOIN forum f
        ON ft.forum_id = f.id
    JOIN tag tg
        ON ft.tag_id = tg.id
    GROUP BY f.id, tg.name
),
top_tag AS (
    SELECT
        forum_id,
        tag_name
    FROM top_tag_per_forum
    WHERE rn = 1
)
SELECT
    f.id,
    f.title,
    concat(p_mod.first_name, ' ', p_mod.last_name) AS moderator_full_name,
    COALESCE(m.member_count, 0) AS member_count,
    COALESCE(ps.post_count, 0) AS post_count,
    ps.avg_post_length,
    ps.median_post_length,
    ps.image_post_pct,
    COALESCE(tc.tag_count, 0) AS tag_count,
    COALESCE(tt.tag_name, 'N/A') AS top_tag_name
FROM forum AS f
LEFT JOIN person AS p_mod
    ON f.moderator_person_id = p_mod.id
LEFT JOIN member_counts AS m
    ON f.id = m.forum_id
LEFT JOIN post_stats AS ps
    ON f.id = ps.forum_id
LEFT JOIN tag_counts AS tc
    ON f.id = tc.forum_id
LEFT JOIN top_tag AS tt
    ON f.id = tt.forum_id
ORDER BY post_count DESC
LIMIT 10

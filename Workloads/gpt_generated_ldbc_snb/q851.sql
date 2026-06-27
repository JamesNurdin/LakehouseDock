WITH tag_stats AS (
    SELECT
        t.id AS tag_id,
        t.name AS tag_name,
        COUNT(p.id) AS post_count,
        COUNT(DISTINCT p.creator_person_id) AS distinct_creator_count,
        AVG(p.length) AS avg_length,
        SUM(p.length) AS total_length
    FROM post_has_tag_tag pht
    JOIN post p ON pht.post_id = p.id
    JOIN tag t ON pht.tag_id = t.id
    GROUP BY t.id, t.name
),

tag_language_counts AS (
    SELECT
        t.id AS tag_id,
        t.name AS tag_name,
        p.language AS language,
        COUNT(p.id) AS language_post_count
    FROM post_has_tag_tag pht
    JOIN post p ON pht.post_id = p.id
    JOIN tag t ON pht.tag_id = t.id
    GROUP BY t.id, t.name, p.language
),

top_language_per_tag AS (
    SELECT
        tag_id,
        tag_name,
        language,
        language_post_count,
        ROW_NUMBER() OVER (PARTITION BY tag_id ORDER BY language_post_count DESC) AS rn
    FROM tag_language_counts
)
SELECT
    ts.tag_id,
    ts.tag_name,
    ts.post_count,
    ts.distinct_creator_count,
    ts.avg_length,
    ts.total_length,
    tl.language AS top_language,
    tl.language_post_count AS top_language_post_count
FROM tag_stats ts
JOIN top_language_per_tag tl
    ON ts.tag_id = tl.tag_id
WHERE tl.rn = 1
ORDER BY ts.post_count DESC
LIMIT 20

WITH tag_stats AS (
    SELECT
        t.id AS tag_id,
        t.name AS tag_name,
        COUNT(p.id) AS total_posts,
        AVG(p.length) AS avg_length,
        COUNT(DISTINCT p.creator_person_id) AS distinct_creators
    FROM post_has_tag_tag pt
    JOIN post p ON pt.post_id = p.id
    JOIN tag t ON pt.tag_id = t.id
    GROUP BY t.id, t.name
),
tag_language_counts AS (
    SELECT
        t.id AS tag_id,
        p.language AS language,
        COUNT(p.id) AS language_post_count,
        ROW_NUMBER() OVER (PARTITION BY t.id ORDER BY COUNT(p.id) DESC) AS rn
    FROM post_has_tag_tag pt
    JOIN post p ON pt.post_id = p.id
    JOIN tag t ON pt.tag_id = t.id
    GROUP BY t.id, p.language
)
SELECT
    ts.tag_id,
    ts.tag_name,
    ts.total_posts,
    ts.avg_length,
    ts.distinct_creators,
    tlc.language AS most_common_language,
    tlc.language_post_count AS most_common_language_post_count
FROM tag_stats ts
LEFT JOIN tag_language_counts tlc
    ON ts.tag_id = tlc.tag_id
    AND tlc.rn = 1
ORDER BY ts.total_posts DESC
LIMIT 20

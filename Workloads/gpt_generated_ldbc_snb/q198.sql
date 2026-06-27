WITH post_tag AS (
    SELECT
        p.container_forum_id,
        p.id AS post_id,
        p.length,
        p.creator_person_id,
        p.creation_date,
        t.id AS tag_id,
        t.name AS tag_name
    FROM post p
    JOIN post_has_tag_tag pht
        ON pht.post_id = p.id
    JOIN tag t
        ON pht.tag_id = t.id
),
tag_stats AS (
    SELECT
        container_forum_id,
        tag_id,
        tag_name,
        COUNT(post_id) AS post_count,
        AVG(length) AS avg_length,
        COUNT(DISTINCT creator_person_id) AS distinct_creators,
        MIN(creation_date) AS earliest_post_date,
        MAX(creation_date) AS latest_post_date
    FROM post_tag
    GROUP BY container_forum_id, tag_id, tag_name
),
ranked AS (
    SELECT
        *,
        ROW_NUMBER() OVER (PARTITION BY container_forum_id ORDER BY post_count DESC) AS rn
    FROM tag_stats
)
SELECT
    container_forum_id,
    tag_id,
    tag_name,
    post_count,
    avg_length,
    distinct_creators,
    earliest_post_date,
    latest_post_date
FROM ranked
WHERE rn = 1
ORDER BY container_forum_id

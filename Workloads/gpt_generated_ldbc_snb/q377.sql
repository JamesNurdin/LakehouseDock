WITH forum_posts AS (
    SELECT
        f.id AS forum_id,
        COUNT(p.id) AS post_count,
        AVG(p.length) AS avg_post_length
    FROM forum f
    LEFT JOIN post p ON p.container_forum_id = f.id
    GROUP BY f.id
),
forum_comments AS (
    SELECT
        f.id AS forum_id,
        COUNT(c.id) AS comment_count,
        AVG(c.length) AS avg_comment_length
    FROM forum f
    LEFT JOIN post p ON p.container_forum_id = f.id
    LEFT JOIN comment c ON c.parent_post_id = p.id
    GROUP BY f.id
),
forum_participants AS (
    SELECT DISTINCT
        f.id AS forum_id,
        per.id AS person_id
    FROM forum f
    JOIN post po ON po.container_forum_id = f.id
    JOIN person per ON po.creator_person_id = per.id
),
forum_tag_counts AS (
    SELECT
        fp.forum_id,
        pt.tag_id,
        COUNT(*) AS tag_count
    FROM forum_participants fp
    JOIN person_has_interest_tag pt ON pt.person_id = fp.person_id
    GROUP BY fp.forum_id, pt.tag_id
),
forum_top_tags AS (
    SELECT
        forum_id,
        tag_id,
        tag_count,
        ROW_NUMBER() OVER (PARTITION BY forum_id ORDER BY tag_count DESC) AS rn
    FROM forum_tag_counts
)
SELECT
    f.id AS forum_id,
    f.title AS forum_title,
    COALESCE(fp.post_count, 0) AS post_count,
    COALESCE(fp.avg_post_length, 0) AS avg_post_length,
    COALESCE(fc.comment_count, 0) AS comment_count,
    COALESCE(fc.avg_comment_length, 0) AS avg_comment_length,
    ARRAY_AGG(tt.tag_id) FILTER (WHERE tt.rn <= 3) AS top_3_tag_ids
FROM forum f
LEFT JOIN forum_posts fp ON fp.forum_id = f.id
LEFT JOIN forum_comments fc ON fc.forum_id = f.id
LEFT JOIN forum_top_tags tt ON tt.forum_id = f.id
GROUP BY f.id, f.title, fp.post_count, fp.avg_post_length, fc.comment_count, fc.avg_comment_length
ORDER BY post_count DESC
LIMIT 20

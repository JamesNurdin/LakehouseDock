WITH post_agg AS (
    SELECT
        f.id AS forum_id,
        f.title AS forum_title,
        COUNT(p.id) AS post_count,
        COALESCE(SUM(p.length), 0) AS total_post_length,
        CASE WHEN COUNT(p.id) > 0 THEN AVG(p.length) END AS avg_post_length
    FROM forum f
    LEFT JOIN post p
        ON p.container_forum_id = f.id
    GROUP BY f.id, f.title
),
comment_agg AS (
    SELECT
        f.id AS forum_id,
        COUNT(c.id) AS comment_count,
        COALESCE(SUM(c.length), 0) AS total_comment_length,
        CASE WHEN COUNT(c.id) > 0 THEN AVG(c.length) END AS avg_comment_length
    FROM forum f
    LEFT JOIN post p
        ON p.container_forum_id = f.id
    LEFT JOIN comment c
        ON c.parent_post_id = p.id
    GROUP BY f.id
),
participant_agg AS (
    SELECT
        forum_id,
        COUNT(DISTINCT person_id) AS participant_count
    FROM (
        SELECT f.id AS forum_id, p.creator_person_id AS person_id
        FROM forum f
        LEFT JOIN post p
            ON p.container_forum_id = f.id
        UNION ALL
        SELECT f.id AS forum_id, c.creator_person_id AS person_id
        FROM forum f
        LEFT JOIN post p
            ON p.container_forum_id = f.id
        LEFT JOIN comment c
            ON c.parent_post_id = p.id
    ) t
    WHERE person_id IS NOT NULL
    GROUP BY forum_id
),
post_tag_usage AS (
    SELECT
        f.id AS forum_id,
        pt.tag_id
    FROM forum f
    LEFT JOIN post p
        ON p.container_forum_id = f.id
    LEFT JOIN post_has_tag_tag pt
        ON pt.post_id = p.id
    WHERE pt.tag_id IS NOT NULL
),
comment_tag_usage AS (
    SELECT
        f.id AS forum_id,
        ct.tag_id
    FROM forum f
    LEFT JOIN post p
        ON p.container_forum_id = f.id
    LEFT JOIN comment c
        ON c.parent_post_id = p.id
    LEFT JOIN comment_has_tag_tag ct
        ON ct.comment_id = c.id
    WHERE ct.tag_id IS NOT NULL
),
forum_tag_counts AS (
    SELECT
        forum_id,
        tag_id,
        COUNT(*) AS tag_use_count
    FROM (
        SELECT forum_id, tag_id FROM post_tag_usage
        UNION ALL
        SELECT forum_id, tag_id FROM comment_tag_usage
    ) t
    GROUP BY forum_id, tag_id
),
top_tags_per_forum AS (
    SELECT
        forum_id,
        tag_id,
        tag_use_count,
        ROW_NUMBER() OVER (PARTITION BY forum_id ORDER BY tag_use_count DESC) AS tag_rank
    FROM forum_tag_counts
)
SELECT
    pa.forum_id,
    pa.forum_title,
    pa.post_count,
    pa.total_post_length,
    pa.avg_post_length,
    ca.comment_count,
    ca.total_comment_length,
    ca.avg_comment_length,
    ppa.participant_count,
    tt.tag_id,
    tt.tag_use_count,
    tt.tag_rank
FROM post_agg pa
LEFT JOIN comment_agg ca
    ON ca.forum_id = pa.forum_id
LEFT JOIN participant_agg ppa
    ON ppa.forum_id = pa.forum_id
LEFT JOIN top_tags_per_forum tt
    ON tt.forum_id = pa.forum_id
    AND tt.tag_rank <= 3
ORDER BY ppa.participant_count DESC, pa.forum_id
LIMIT 20

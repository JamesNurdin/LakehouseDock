WITH post_stats AS (
    SELECT
        p.container_forum_id AS forum_id,
        COUNT(*) AS total_posts,
        AVG(p.length) AS avg_post_length
    FROM post p
    GROUP BY p.container_forum_id
),
comment_stats AS (
    SELECT
        p.container_forum_id AS forum_id,
        COUNT(*) AS total_comments,
        AVG(c.length) AS avg_comment_length
    FROM comment c
    JOIN post p
        ON c.parent_post_id = p.id
    GROUP BY p.container_forum_id
),
participants_stats AS (
    SELECT
        forum_id,
        COUNT(DISTINCT person_id) AS distinct_participants
    FROM (
        SELECT
            p.container_forum_id AS forum_id,
            p.creator_person_id AS person_id
        FROM post p
        UNION ALL
        SELECT
            p.container_forum_id AS forum_id,
            c.creator_person_id AS person_id
        FROM comment c
        JOIN post p
            ON c.parent_post_id = p.id
    ) u
    GROUP BY forum_id
),
tag_usage_raw AS (
    -- Tag usage from posts
    SELECT
        p.container_forum_id AS forum_id,
        t.id AS tag_id,
        t.name AS tag_name,
        COUNT(*) AS tag_usage
    FROM post p
    JOIN post_has_tag_tag pht
        ON p.id = pht.post_id
    JOIN tag t
        ON pht.tag_id = t.id
    GROUP BY p.container_forum_id, t.id, t.name

    UNION ALL

    -- Tag usage from comments
    SELECT
        p.container_forum_id AS forum_id,
        t.id AS tag_id,
        t.name AS tag_name,
        COUNT(*) AS tag_usage
    FROM comment c
    JOIN post p
        ON c.parent_post_id = p.id
    JOIN comment_has_tag_tag cht
        ON c.id = cht.comment_id
    JOIN tag t
        ON cht.tag_id = t.id
    GROUP BY p.container_forum_id, t.id, t.name
),
tag_usage_agg AS (
    SELECT
        forum_id,
        tag_id,
        tag_name,
        SUM(tag_usage) AS total_usage
    FROM tag_usage_raw
    GROUP BY forum_id, tag_id, tag_name
),
top_tag_per_forum AS (
    SELECT
        forum_id,
        tag_name,
        total_usage
    FROM (
        SELECT
            forum_id,
            tag_name,
            total_usage,
            ROW_NUMBER() OVER (PARTITION BY forum_id ORDER BY total_usage DESC, tag_name) AS rn
        FROM tag_usage_agg
    )
    WHERE rn = 1
)
SELECT
    f.id AS forum_id,
    f.title AS forum_title,
    COALESCE(ps.total_posts, 0) AS total_posts,
    ps.avg_post_length,
    COALESCE(cs.total_comments, 0) AS total_comments,
    cs.avg_comment_length,
    COALESCE(par.distinct_participants, 0) AS distinct_participants,
    tt.tag_name AS top_tag,
    tt.total_usage AS top_tag_usage
FROM forum f
LEFT JOIN post_stats ps
    ON f.id = ps.forum_id
LEFT JOIN comment_stats cs
    ON f.id = cs.forum_id
LEFT JOIN participants_stats par
    ON f.id = par.forum_id
LEFT JOIN top_tag_per_forum tt
    ON f.id = tt.forum_id
ORDER BY total_posts DESC
LIMIT 20

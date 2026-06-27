WITH
    post_stats AS (
        SELECT
            f.id AS forum_id,
            COUNT(p.id) AS total_posts,
            AVG(p.length) AS avg_post_length,
            COUNT(DISTINCT p.creator_person_id) AS distinct_post_authors
        FROM forum f
        LEFT JOIN post p
            ON p.container_forum_id = f.id
        GROUP BY f.id
    ),
    post_tag_counts AS (
        SELECT
            f.id AS forum_id,
            COUNT(DISTINCT pt.tag_id) AS distinct_post_tags
        FROM forum f
        LEFT JOIN post p
            ON p.container_forum_id = f.id
        LEFT JOIN post_has_tag_tag pt
            ON pt.post_id = p.id
        GROUP BY f.id
    ),
    comment_stats AS (
        SELECT
            f.id AS forum_id,
            COUNT(c.id) AS total_comments,
            AVG(c.length) AS avg_comment_length,
            COUNT(DISTINCT c.creator_person_id) AS distinct_comment_authors
        FROM forum f
        LEFT JOIN post p
            ON p.container_forum_id = f.id
        LEFT JOIN comment c
            ON c.parent_post_id = p.id
        GROUP BY f.id
    ),
    comment_tag_counts AS (
        SELECT
            f.id AS forum_id,
            COUNT(DISTINCT ct.tag_id) AS distinct_comment_tags
        FROM forum f
        LEFT JOIN post p
            ON p.container_forum_id = f.id
        LEFT JOIN comment c
            ON c.parent_post_id = p.id
        LEFT JOIN comment_has_tag_tag ct
            ON ct.comment_id = c.id
        GROUP BY f.id
    ),
    distinct_authors_agg AS (
        SELECT
            forum_id,
            COUNT(DISTINCT author_id) AS distinct_authors
        FROM (
            SELECT p.container_forum_id AS forum_id, p.creator_person_id AS author_id
            FROM post p
            UNION
            SELECT p.container_forum_id AS forum_id, c.creator_person_id AS author_id
            FROM comment c
            JOIN post p
                ON c.parent_post_id = p.id
        ) fa
        GROUP BY forum_id
    )
SELECT
    f.id AS forum_id,
    f.title,
    COALESCE(ps.total_posts, 0) AS total_posts,
    COALESCE(cs.total_comments, 0) AS total_comments,
    ps.avg_post_length,
    cs.avg_comment_length,
    ptc.distinct_post_tags,
    ctc.distinct_comment_tags,
    da.distinct_authors
FROM forum f
LEFT JOIN post_stats ps
    ON ps.forum_id = f.id
LEFT JOIN comment_stats cs
    ON cs.forum_id = f.id
LEFT JOIN post_tag_counts ptc
    ON ptc.forum_id = f.id
LEFT JOIN comment_tag_counts ctc
    ON ctc.forum_id = f.id
LEFT JOIN distinct_authors_agg da
    ON da.forum_id = f.id
ORDER BY total_posts DESC
LIMIT 10

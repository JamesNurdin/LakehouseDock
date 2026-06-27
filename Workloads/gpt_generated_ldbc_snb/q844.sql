WITH
    -- Number of posts and average post length per forum
    posts AS (
        SELECT
            f.id AS forum_id,
            COUNT(p.id) AS post_count,
            AVG(p.length) AS avg_post_length
        FROM forum f
        JOIN post p ON p.container_forum_id = f.id
        GROUP BY f.id
    ),
    -- Number of comments and average comment length per forum (comments on posts belonging to the forum)
    comments AS (
        SELECT
            f.id AS forum_id,
            COUNT(c.id) AS comment_count,
            AVG(c.length) AS avg_comment_length
        FROM forum f
        JOIN post p ON p.container_forum_id = f.id
        JOIN comment c ON c.parent_post_id = p.id
        GROUP BY f.id
    ),
    -- Distinct members of each forum
    members AS (
        SELECT
            f.id AS forum_id,
            COUNT(DISTINCT fm.person_id) AS member_count
        FROM forum f
        JOIN forum_has_member_person fm ON fm.forum_id = f.id
        GROUP BY f.id
    ),
    -- Tags that appear on posts in a forum
    post_tags AS (
        SELECT
            f.id AS forum_id,
            pht.tag_id
        FROM forum f
        JOIN post p ON p.container_forum_id = f.id
        JOIN post_has_tag_tag pht ON pht.post_id = p.id
    ),
    -- Tags that appear on comments (which are on posts) in a forum
    comment_tags AS (
        SELECT
            f.id AS forum_id,
            cht.tag_id
        FROM forum f
        JOIN post p ON p.container_forum_id = f.id
        JOIN comment c ON c.parent_post_id = p.id
        JOIN comment_has_tag_tag cht ON cht.comment_id = c.id
    ),
    -- Distinct tag count per forum (union of post‑ and comment‑tags)
    distinct_tags AS (
        SELECT
            forum_id,
            COUNT(DISTINCT tag_id) AS distinct_tag_count
        FROM (
            SELECT forum_id, tag_id FROM post_tags
            UNION ALL
            SELECT forum_id, tag_id FROM comment_tags
        ) AS all_tags
        GROUP BY forum_id
    ),
    -- Likes on posts and comments per forum
    likes AS (
        SELECT
            f.id AS forum_id,
            COUNT(DISTINCT plp.person_id) AS post_like_count,
            COUNT(DISTINCT plc.person_id) AS comment_like_count
        FROM forum f
        LEFT JOIN post p ON p.container_forum_id = f.id
        LEFT JOIN person_likes_post plp ON plp.post_id = p.id
        LEFT JOIN comment c ON c.parent_post_id = p.id
        LEFT JOIN person_likes_comment plc ON plc.comment_id = c.id
        GROUP BY f.id
    )
SELECT
    f.id AS forum_id,
    f.title,
    COALESCE(p.post_count, 0) AS post_count,
    COALESCE(p.avg_post_length, 0) AS avg_post_length,
    COALESCE(c.comment_count, 0) AS comment_count,
    COALESCE(c.avg_comment_length, 0) AS avg_comment_length,
    COALESCE(m.member_count, 0) AS member_count,
    COALESCE(t.distinct_tag_count, 0) AS distinct_tag_count,
    COALESCE(l.post_like_count, 0) AS post_like_count,
    COALESCE(l.comment_like_count, 0) AS comment_like_count
FROM forum f
LEFT JOIN posts p        ON p.forum_id = f.id
LEFT JOIN comments c     ON c.forum_id = f.id
LEFT JOIN members m      ON m.forum_id = f.id
LEFT JOIN distinct_tags t ON t.forum_id = f.id
LEFT JOIN likes l        ON l.forum_id = f.id
ORDER BY f.id

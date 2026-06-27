WITH forum_stats AS (
    SELECT
        f.id AS forum_id,
        f.title AS forum_title,
        COUNT(DISTINCT p.id) AS post_count,
        AVG(p.length) AS avg_post_length,
        SUM(p.length) AS total_post_length,
        COUNT(DISTINCT c.id) AS comment_count,
        AVG(c.length) AS avg_comment_length,
        SUM(c.length) AS total_comment_length,
        COUNT(DISTINCT plp.person_id) AS distinct_post_likers,
        COUNT(DISTINCT plc.person_id) AS distinct_comment_likers,
        COUNT(DISTINCT fm.person_id) AS member_count
    FROM forum f
    LEFT JOIN post p ON p.container_forum_id = f.id
    LEFT JOIN person_likes_post plp ON plp.post_id = p.id
    LEFT JOIN comment c ON c.parent_post_id = p.id
    LEFT JOIN person_likes_comment plc ON plc.comment_id = c.id
    LEFT JOIN forum_has_member_person fm ON fm.forum_id = f.id
    GROUP BY f.id, f.title
),
forum_tags AS (
    SELECT f.id AS forum_id, t.id AS tag_id
    FROM forum f
    JOIN post p ON p.container_forum_id = f.id
    JOIN post_has_tag_tag pht ON pht.post_id = p.id
    JOIN tag t ON t.id = pht.tag_id
    UNION
    SELECT f.id AS forum_id, t.id AS tag_id
    FROM forum f
    JOIN post p ON p.container_forum_id = f.id
    JOIN comment c ON c.parent_post_id = p.id
    JOIN comment_has_tag_tag cht ON cht.comment_id = c.id
    JOIN tag t ON t.id = cht.tag_id
),
forum_tag_counts AS (
    SELECT forum_id, COUNT(DISTINCT tag_id) AS distinct_tags_used
    FROM forum_tags
    GROUP BY forum_id
)
SELECT
    fs.forum_id,
    fs.forum_title,
    fs.post_count,
    fs.avg_post_length,
    fs.total_post_length,
    fs.comment_count,
    fs.avg_comment_length,
    fs.total_comment_length,
    fs.distinct_post_likers,
    fs.distinct_comment_likers,
    ftc.distinct_tags_used,
    fs.member_count
FROM forum_stats fs
LEFT JOIN forum_tag_counts ftc ON ftc.forum_id = fs.forum_id
ORDER BY fs.post_count DESC
LIMIT 10

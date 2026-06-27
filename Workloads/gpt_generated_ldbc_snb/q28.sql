WITH tag_posts AS (
    SELECT
        t.id AS tag_id,
        t.name AS tag_name,
        COUNT(DISTINCT p.id) AS post_count,
        SUM(p.length) AS total_post_length,
        AVG(p.length) AS avg_post_length,
        COUNT(DISTINCT p.creator_person_id) AS distinct_post_creator_count
    FROM post_has_tag_tag pht
    JOIN post p ON pht.post_id = p.id
    JOIN tag t ON pht.tag_id = t.id
    GROUP BY t.id, t.name
),
tag_comments AS (
    SELECT
        t.id AS tag_id,
        COUNT(DISTINCT c.id) AS comment_count,
        SUM(c.length) AS total_comment_length,
        COUNT(DISTINCT c.creator_person_id) AS distinct_comment_creator_count
    FROM post_has_tag_tag pht
    JOIN post p ON pht.post_id = p.id
    JOIN comment c ON c.parent_post_id = p.id
    JOIN tag t ON pht.tag_id = t.id
    GROUP BY t.id
),
tag_likes AS (
    SELECT
        t.id AS tag_id,
        COUNT(plp.person_id) AS total_like_count,
        COUNT(DISTINCT plp.person_id) AS distinct_liker_count
    FROM post_has_tag_tag pht
    JOIN post p ON pht.post_id = p.id
    JOIN person_likes_post plp ON plp.post_id = p.id
    JOIN tag t ON pht.tag_id = t.id
    GROUP BY t.id
)
SELECT
    tp.tag_id,
    tp.tag_name,
    tp.post_count,
    tp.total_post_length,
    tp.avg_post_length,
    tp.distinct_post_creator_count,
    COALESCE(tc.comment_count, 0) AS comment_count,
    COALESCE(tc.total_comment_length, 0) AS total_comment_length,
    COALESCE(tc.distinct_comment_creator_count, 0) AS distinct_comment_creator_count,
    COALESCE(tl.total_like_count, 0) AS total_like_count,
    COALESCE(tl.distinct_liker_count, 0) AS distinct_liker_count
FROM tag_posts tp
LEFT JOIN tag_comments tc ON tp.tag_id = tc.tag_id
LEFT JOIN tag_likes tl ON tp.tag_id = tl.tag_id
ORDER BY tp.post_count DESC
LIMIT 100

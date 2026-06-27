WITH post_likes AS (
    SELECT
        tag.id AS tag_id,
        tag.name AS tag_name,
        COUNT(DISTINCT person_likes_post.person_id) AS post_like_count
    FROM post_has_tag_tag
    JOIN post ON post_has_tag_tag.post_id = post.id
    JOIN tag ON post_has_tag_tag.tag_id = tag.id
    JOIN person_likes_post ON person_likes_post.post_id = post.id
    JOIN person ON person_likes_post.person_id = person.id
    JOIN place ON post.location_country_id = place.id
    WHERE place.name = 'United Kingdom'
    GROUP BY tag.id, tag.name
),
comment_likes AS (
    SELECT
        tag.id AS tag_id,
        tag.name AS tag_name,
        COUNT(DISTINCT person_likes_comment.person_id) AS comment_like_count
    FROM comment_has_tag_tag
    JOIN comment ON comment_has_tag_tag.comment_id = comment.id
    JOIN tag ON comment_has_tag_tag.tag_id = tag.id
    JOIN person_likes_comment ON person_likes_comment.comment_id = comment.id
    JOIN person ON person_likes_comment.person_id = person.id
    JOIN place ON comment.location_country_id = place.id
    WHERE place.name = 'United Kingdom'
    GROUP BY tag.id, tag.name
)
SELECT
    COALESCE(p.tag_id, c.tag_id) AS tag_id,
    COALESCE(p.tag_name, c.tag_name) AS tag_name,
    COALESCE(p.post_like_count, 0) AS post_like_count,
    COALESCE(c.comment_like_count, 0) AS comment_like_count,
    COALESCE(p.post_like_count, 0) + COALESCE(c.comment_like_count, 0) AS total_likes
FROM post_likes p
FULL OUTER JOIN comment_likes c ON p.tag_id = c.tag_id
ORDER BY total_likes DESC
LIMIT 10

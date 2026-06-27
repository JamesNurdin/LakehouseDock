WITH comment_stats AS (
    SELECT
        person.id AS person_id,
        COUNT(DISTINCT comment.id) AS comment_count,
        COALESCE(SUM(comment.length), 0) AS total_comment_length,
        COALESCE(AVG(comment.length), 0) AS avg_comment_length,
        COUNT(DISTINCT comment_has_tag_tag.tag_id) AS comment_tag_count,
        COUNT(DISTINCT place.id) AS comment_country_count
    FROM person
    LEFT JOIN comment
        ON comment.creator_person_id = person.id
    LEFT JOIN comment_has_tag_tag
        ON comment_has_tag_tag.comment_id = comment.id
    LEFT JOIN place
        ON comment.location_country_id = place.id
    GROUP BY person.id
),
post_stats AS (
    SELECT
        person.id AS person_id,
        COUNT(DISTINCT post.id) AS post_count,
        COUNT(DISTINCT post_has_tag_tag.tag_id) AS post_tag_count
    FROM person
    LEFT JOIN post
        ON post.creator_person_id = person.id
    LEFT JOIN post_has_tag_tag
        ON post_has_tag_tag.post_id = post.id
    GROUP BY person.id
),
like_stats AS (
    SELECT
        person.id AS person_id,
        COUNT(DISTINCT person_likes_comment.comment_id) AS liked_comment_count
    FROM person
    LEFT JOIN person_likes_comment
        ON person_likes_comment.person_id = person.id
    GROUP BY person.id
)
SELECT
    p.id,
    p.first_name,
    p.last_name,
    COALESCE(cs.comment_count, 0) AS comment_count,
    COALESCE(cs.total_comment_length, 0) AS total_comment_length,
    COALESCE(cs.avg_comment_length, 0) AS avg_comment_length,
    COALESCE(cs.comment_tag_count, 0) AS comment_tag_count,
    COALESCE(cs.comment_country_count, 0) AS comment_country_count,
    COALESCE(ps.post_count, 0) AS post_count,
    COALESCE(ps.post_tag_count, 0) AS post_tag_count,
    COALESCE(ls.liked_comment_count, 0) AS liked_comment_count
FROM person p
LEFT JOIN comment_stats cs
    ON cs.person_id = p.id
LEFT JOIN post_stats ps
    ON ps.person_id = p.id
LEFT JOIN like_stats ls
    ON ls.person_id = p.id
ORDER BY cs.comment_count DESC, p.id

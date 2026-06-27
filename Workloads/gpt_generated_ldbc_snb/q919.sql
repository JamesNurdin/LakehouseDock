WITH comment_basic AS (
    SELECT
        c.creator_person_id AS person_id,
        COUNT(*) AS comments_created,
        AVG(c.length) AS avg_comment_length,
        COUNT(DISTINCT c.location_country_id) AS distinct_comment_countries
    FROM comment c
    GROUP BY c.creator_person_id
),
comment_tags AS (
    SELECT
        c.creator_person_id AS person_id,
        COUNT(DISTINCT t.tag_id) AS distinct_tags_on_comments
    FROM comment c
    LEFT JOIN comment_has_tag_tag t
        ON t.comment_id = c.id
    GROUP BY c.creator_person_id
),
like_metrics AS (
    SELECT
        pc.person_id AS person_id,
        COUNT(*) AS comments_liked
    FROM person_likes_comment pc
    GROUP BY pc.person_id
),
post_metrics AS (
    SELECT
        po.creator_person_id AS person_id,
        COUNT(*) AS posts_created,
        COUNT(DISTINCT po.location_country_id) AS distinct_post_countries
    FROM post po
    GROUP BY po.creator_person_id
)
SELECT
    p.id AS person_id,
    p.first_name,
    p.last_name,
    p.gender,
    COALESCE(cb.comments_created, 0) AS comments_created,
    COALESCE(cb.avg_comment_length, 0) AS avg_comment_length,
    COALESCE(cb.distinct_comment_countries, 0) AS distinct_comment_countries,
    COALESCE(ct.distinct_tags_on_comments, 0) AS distinct_tags_on_comments,
    COALESCE(lm.comments_liked, 0) AS comments_liked,
    COALESCE(pm.posts_created, 0) AS posts_created,
    COALESCE(pm.distinct_post_countries, 0) AS distinct_post_countries
FROM person p
LEFT JOIN comment_basic cb
    ON cb.person_id = p.id
LEFT JOIN comment_tags ct
    ON ct.person_id = p.id
LEFT JOIN like_metrics lm
    ON lm.person_id = p.id
LEFT JOIN post_metrics pm
    ON pm.person_id = p.id
ORDER BY comments_created DESC
LIMIT 100

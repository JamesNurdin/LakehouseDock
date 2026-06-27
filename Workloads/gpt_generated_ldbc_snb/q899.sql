WITH comment_likes AS (
    SELECT
        plc.person_id,
        COUNT(DISTINCT plc.comment_id) AS comments_liked
    FROM person_likes_comment plc
    GROUP BY plc.person_id
),
post_likes AS (
    SELECT
        plp.person_id,
        COUNT(DISTINCT plp.post_id) AS posts_liked
    FROM person_likes_post plp
    GROUP BY plp.person_id
),
friend_counts AS (
    SELECT
        pk.person_id,
        COUNT(DISTINCT pk.friend_id) AS friend_count
    FROM (
        SELECT person1_id AS person_id, person2_id AS friend_id FROM person_knows_person
        UNION ALL
        SELECT person2_id AS person_id, person1_id AS friend_id FROM person_knows_person
    ) pk
    GROUP BY pk.person_id
),
interest_counts AS (
    SELECT
        pit.person_id,
        COUNT(DISTINCT pit.tag_id) AS interest_count
    FROM person_has_interest_tag pit
    GROUP BY pit.person_id
),
post_counts AS (
    SELECT
        po.creator_person_id AS person_id,
        COUNT(DISTINCT po.id) AS posts_created
    FROM post po
    GROUP BY po.creator_person_id
)
SELECT
    p.id AS person_id,
    p.first_name,
    p.last_name,
    COALESCE(cl.comments_liked, 0) AS comments_liked,
    COALESCE(pl.posts_liked, 0) AS posts_liked,
    COALESCE(fc.friend_count, 0) AS friend_count,
    COALESCE(ic.interest_count, 0) AS interest_count,
    COALESCE(pc.posts_created, 0) AS posts_created,
    (COALESCE(cl.comments_liked, 0) + COALESCE(pl.posts_liked, 0) + COALESCE(fc.friend_count, 0) + COALESCE(ic.interest_count, 0) + COALESCE(pc.posts_created, 0)) AS activity_score
FROM person p
LEFT JOIN comment_likes cl ON cl.person_id = p.id
LEFT JOIN post_likes pl ON pl.person_id = p.id
LEFT JOIN friend_counts fc ON fc.person_id = p.id
LEFT JOIN interest_counts ic ON ic.person_id = p.id
LEFT JOIN post_counts pc ON pc.person_id = p.id
ORDER BY activity_score DESC
LIMIT 10

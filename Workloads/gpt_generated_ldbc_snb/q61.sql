WITH member_stats AS (
    SELECT
        fhm.forum_id,
        COUNT(DISTINCT p.id) AS member_count,
        COUNT(DISTINCT CASE WHEN p.gender = 'male' THEN p.id END) AS male_member_count,
        COUNT(DISTINCT CASE WHEN p.gender = 'female' THEN p.id END) AS female_member_count
    FROM forum_has_member_person fhm
    JOIN person p
        ON fhm.person_id = p.id
    GROUP BY fhm.forum_id
),
post_stats AS (
    SELECT
        fhm.forum_id,
        COUNT(DISTINCT post.id) AS post_count,
        AVG(post.length) AS avg_post_length
    FROM forum_has_member_person fhm
    JOIN person p
        ON fhm.person_id = p.id
    JOIN post
        ON post.creator_person_id = p.id
    GROUP BY fhm.forum_id
),
likes_received AS (
    SELECT
        fhm.forum_id,
        COUNT(*) AS likes_on_member_posts
    FROM forum_has_member_person fhm
    JOIN person p
        ON fhm.person_id = p.id
    JOIN post
        ON post.creator_person_id = p.id
    JOIN person_likes_post plp
        ON plp.post_id = post.id
    GROUP BY fhm.forum_id
),
likes_given AS (
    SELECT
        fhm.forum_id,
        COUNT(*) AS likes_given_by_members
    FROM forum_has_member_person fhm
    JOIN person p
        ON fhm.person_id = p.id
    JOIN person_likes_post plp
        ON plp.person_id = p.id
    GROUP BY fhm.forum_id
)
SELECT
    ms.forum_id,
    ms.member_count,
    ms.male_member_count,
    ms.female_member_count,
    COALESCE(ps.post_count, 0) AS post_count,
    COALESCE(ps.avg_post_length, 0) AS avg_post_length,
    COALESCE(lr.likes_on_member_posts, 0) AS total_likes_on_member_posts,
    COALESCE(lg.likes_given_by_members, 0) AS total_likes_given_by_members
FROM member_stats ms
LEFT JOIN post_stats ps
    ON ms.forum_id = ps.forum_id
LEFT JOIN likes_received lr
    ON ms.forum_id = lr.forum_id
LEFT JOIN likes_given lg
    ON ms.forum_id = lg.forum_id
ORDER BY ms.member_count DESC
LIMIT 10

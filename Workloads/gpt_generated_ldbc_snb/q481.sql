WITH comment_agg AS (
    SELECT
        c.creator_person_id AS person_id,
        COUNT(c.id) AS total_comments,
        AVG(c.length) AS avg_comment_length,
        COUNT(DISTINCT pl.id) AS distinct_comment_countries
    FROM comment c
    LEFT JOIN place pl ON c.location_country_id = pl.id AND pl.type = 'Country'
    GROUP BY c.creator_person_id
),
interest_agg AS (
    SELECT
        person_id,
        COUNT(DISTINCT tag_id) AS distinct_interests
    FROM person_has_interest_tag
    GROUP BY person_id
),
likes_agg AS (
    SELECT
        person_id,
        COUNT(DISTINCT post_id) AS liked_posts
    FROM person_likes_post
    GROUP BY person_id
),
friends_agg AS (
    SELECT
        person_id,
        COUNT(DISTINCT friend_id) AS number_of_friends
    FROM (
        SELECT person1_id AS person_id, person2_id AS friend_id FROM person_knows_person
        UNION ALL
        SELECT person2_id AS person_id, person1_id AS friend_id FROM person_knows_person
    ) AS f
    GROUP BY person_id
),
forum_membership_agg AS (
    SELECT
        person_id,
        COUNT(DISTINCT forum_id) AS forum_memberships
    FROM forum_has_member_person
    GROUP BY person_id
)
SELECT
    p.id,
    p.first_name,
    p.last_name,
    COALESCE(ca.total_comments, 0) AS total_comments,
    COALESCE(ca.avg_comment_length, 0) AS avg_comment_length,
    COALESCE(ca.distinct_comment_countries, 0) AS distinct_comment_countries,
    COALESCE(ia.distinct_interests, 0) AS distinct_interests,
    COALESCE(la.liked_posts, 0) AS liked_posts,
    COALESCE(fa.number_of_friends, 0) AS number_of_friends,
    COALESCE(fma.forum_memberships, 0) AS forum_memberships
FROM person p
LEFT JOIN comment_agg ca ON ca.person_id = p.id
LEFT JOIN interest_agg ia ON ia.person_id = p.id
LEFT JOIN likes_agg la ON la.person_id = p.id
LEFT JOIN friends_agg fa ON fa.person_id = p.id
LEFT JOIN forum_membership_agg fma ON fma.person_id = p.id
ORDER BY total_comments DESC
LIMIT 10

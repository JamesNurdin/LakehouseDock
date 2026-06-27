WITH
    -- Count each distinct friendship (both directions) for every person
    person_friends AS (
        SELECT person1_id AS person_id, person2_id AS friend_id
        FROM person_knows_person
        UNION ALL
        SELECT person2_id AS person_id, person1_id AS friend_id
        FROM person_knows_person
    ),
    friend_counts AS (
        SELECT person_id,
               COUNT(DISTINCT friend_id) AS num_friends
        FROM person_friends
        GROUP BY person_id
    ),
    -- Aggregate post statistics per creator
    post_stats AS (
        SELECT creator_person_id AS person_id,
               COUNT(*) AS num_posts,
               AVG(length) AS avg_post_length
        FROM post
        GROUP BY creator_person_id
    ),
    -- Aggregate comment statistics per creator
    comment_stats AS (
        SELECT creator_person_id AS person_id,
               COUNT(*) AS num_comments,
               AVG(length) AS avg_comment_length
        FROM comment
        GROUP BY creator_person_id
    ),
    -- Total likes a person has given (on posts + comments)
    likes_given AS (
        SELECT person_id,
               COUNT(*) AS likes_given
        FROM (
            SELECT person_id FROM person_likes_post
            UNION ALL
            SELECT person_id FROM person_likes_comment
        ) l
        GROUP BY person_id
    ),
    -- Likes received on a person's posts
    likes_received_posts AS (
        SELECT po.creator_person_id AS person_id,
               COUNT(plp.person_id) AS likes_received_posts
        FROM post po
        LEFT JOIN person_likes_post plp ON plp.post_id = po.id
        GROUP BY po.creator_person_id
    ),
    -- Likes received on a person's comments
    likes_received_comments AS (
        SELECT co.creator_person_id AS person_id,
               COUNT(plc.person_id) AS likes_received_comments
        FROM comment co
        LEFT JOIN person_likes_comment plc ON plc.comment_id = co.id
        GROUP BY co.creator_person_id
    ),
    -- Count distinct interest tags per person
    interest_counts AS (
        SELECT person_id,
               COUNT(DISTINCT tag_id) AS num_interests
        FROM person_has_interest_tag
        GROUP BY person_id
    ),
    -- Count distinct forums a person belongs to
    forum_membership_counts AS (
        SELECT person_id,
               COUNT(DISTINCT forum_id) AS num_forums
        FROM forum_has_member_person
        GROUP BY person_id
    ),
    -- Resolve the city name for each person (if available)
    person_city AS (
        SELECT p.id AS person_id,
               pl.name AS city_name,
               pl.id   AS city_id
        FROM person p
        LEFT JOIN place pl ON p.location_city_id = pl.id
    )
SELECT
    p.id,
    p.first_name,
    p.last_name,
    pc.city_name,
    COALESCE(fc.num_friends, 0)                               AS num_friends,
    COALESCE(ps.num_posts, 0)                                 AS num_posts,
    COALESCE(ps.avg_post_length, 0)                           AS avg_post_length,
    COALESCE(cs.num_comments, 0)                              AS num_comments,
    COALESCE(cs.avg_comment_length, 0)                        AS avg_comment_length,
    COALESCE(lg.likes_given, 0)                               AS likes_given,
    COALESCE(lrp.likes_received_posts, 0) +
    COALESCE(lrc.likes_received_comments, 0)                  AS likes_received,
    COALESCE(ic.num_interests, 0)                             AS num_interests,
    COALESCE(fm.num_forums, 0)                                AS num_forums
FROM person p
LEFT JOIN person_city pc ON pc.person_id = p.id
LEFT JOIN friend_counts fc ON fc.person_id = p.id
LEFT JOIN post_stats ps ON ps.person_id = p.id
LEFT JOIN comment_stats cs ON cs.person_id = p.id
LEFT JOIN likes_given lg ON lg.person_id = p.id
LEFT JOIN likes_received_posts lrp ON lrp.person_id = p.id
LEFT JOIN likes_received_comments lrc ON lrc.person_id = p.id
LEFT JOIN interest_counts ic ON ic.person_id = p.id
LEFT JOIN forum_membership_counts fm ON fm.person_id = p.id
ORDER BY num_friends DESC, num_posts DESC
LIMIT 100

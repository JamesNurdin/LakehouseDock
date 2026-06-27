WITH
    post_counts AS (
        SELECT creator_person_id AS person_id,
               COUNT(*) AS post_count
        FROM post
        GROUP BY creator_person_id
    ),
    comment_counts AS (
        SELECT creator_person_id AS person_id,
               COUNT(*) AS comment_count
        FROM comment
        GROUP BY creator_person_id
    ),
    post_likes AS (
        SELECT p.creator_person_id AS person_id,
               COUNT(*) AS post_likes_received
        FROM post p
        JOIN person_likes_post plp
          ON p.id = plp.post_id
        GROUP BY p.creator_person_id
    ),
    comment_likes AS (
        SELECT c.creator_person_id AS person_id,
               COUNT(*) AS comment_likes_received
        FROM comment c
        JOIN person_likes_comment plc
          ON c.id = plc.comment_id
        GROUP BY c.creator_person_id
    ),
    friend_pairs AS (
        SELECT person1_id AS person_id,
               person2_id AS friend_id
        FROM person_knows_person
        UNION ALL
        SELECT person2_id AS person_id,
               person1_id AS friend_id
        FROM person_knows_person
    ),
    friend_counts AS (
        SELECT person_id,
               COUNT(DISTINCT friend_id) AS friend_count
        FROM friend_pairs
        GROUP BY person_id
    ),
    interest_counts AS (
        SELECT person_id,
               COUNT(DISTINCT tag_id) AS interest_tag_count
        FROM person_has_interest_tag
        GROUP BY person_id
    ),
    membership_counts AS (
        SELECT person_id,
               COUNT(DISTINCT forum_id) AS forum_membership_count
        FROM forum_has_member_person
        GROUP BY person_id
    ),
    moderated_counts AS (
        SELECT moderator_person_id AS person_id,
               COUNT(*) AS forum_moderated_count
        FROM forum
        GROUP BY moderator_person_id
    )
SELECT
    p.id,
    p.first_name,
    p.last_name,
    COALESCE(pc.post_count, 0)               AS post_count,
    COALESCE(cc.comment_count, 0)            AS comment_count,
    COALESCE(pl.post_likes_received, 0)      AS post_likes_received,
    COALESCE(cl.comment_likes_received, 0)   AS comment_likes_received,
    COALESCE(fc.friend_count, 0)             AS friend_count,
    COALESCE(ic.interest_tag_count, 0)      AS interest_tag_count,
    COALESCE(mc.forum_membership_count, 0)  AS forum_membership_count,
    COALESCE(mdc.forum_moderated_count, 0)  AS forum_moderated_count,
    (COALESCE(pl.post_likes_received, 0) +
     COALESCE(cl.comment_likes_received, 0) +
     COALESCE(fc.friend_count, 0) * 2 +
     COALESCE(pc.post_count, 0) +
     COALESCE(cc.comment_count, 0))        AS influence_score
FROM person p
LEFT JOIN post_counts pc      ON p.id = pc.person_id
LEFT JOIN comment_counts cc   ON p.id = cc.person_id
LEFT JOIN post_likes pl       ON p.id = pl.person_id
LEFT JOIN comment_likes cl    ON p.id = cl.person_id
LEFT JOIN friend_counts fc    ON p.id = fc.person_id
LEFT JOIN interest_counts ic  ON p.id = ic.person_id
LEFT JOIN membership_counts mc ON p.id = mc.person_id
LEFT JOIN moderated_counts mdc ON p.id = mdc.person_id
ORDER BY influence_score DESC
LIMIT 10

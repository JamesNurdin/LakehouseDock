WITH post_counts AS (
    SELECT po.creator_person_id AS person_id,
           COUNT(*) AS post_cnt
    FROM post po
    GROUP BY po.creator_person_id
),
comment_counts AS (
    SELECT c.creator_person_id AS person_id,
           COUNT(*) AS comment_cnt
    FROM comment c
    GROUP BY c.creator_person_id
),
likes_post_counts AS (
    SELECT plp.person_id,
           COUNT(*) AS likes_post_cnt
    FROM person_likes_post plp
    GROUP BY plp.person_id
),
likes_comment_counts AS (
    SELECT plc.person_id,
           COUNT(*) AS likes_comment_cnt
    FROM person_likes_comment plc
    GROUP BY plc.person_id
),
interest_counts AS (
    SELECT phi.person_id,
           COUNT(*) AS interest_cnt
    FROM person_has_interest_tag phi
    GROUP BY phi.person_id
),
friends AS (
    SELECT pkp.person1_id AS person_id,
           pkp.person2_id AS friend_id
    FROM person_knows_person pkp
    UNION ALL
    SELECT pkp.person2_id AS person_id,
           pkp.person1_id AS friend_id
    FROM person_knows_person pkp
),
friend_counts AS (
    SELECT person_id,
           COUNT(DISTINCT friend_id) AS friend_cnt
    FROM friends
    GROUP BY person_id
)
SELECT
    p.id,
    p.first_name,
    p.last_name,
    COALESCE(pc.post_cnt, 0)            AS post_cnt,
    COALESCE(cc.comment_cnt, 0)         AS comment_cnt,
    COALESCE(lpc.likes_post_cnt, 0)    AS likes_post_cnt,
    COALESCE(lcc.likes_comment_cnt, 0) AS likes_comment_cnt,
    COALESCE(fc.friend_cnt, 0)          AS friend_cnt,
    COALESCE(ic.interest_cnt, 0)        AS interest_cnt,
    (COALESCE(pc.post_cnt, 0) + COALESCE(cc.comment_cnt, 0) +
     COALESCE(lpc.likes_post_cnt, 0) + COALESCE(lcc.likes_comment_cnt, 0) +
     COALESCE(fc.friend_cnt, 0) + COALESCE(ic.interest_cnt, 0)) AS total_activity
FROM person p
LEFT JOIN post_counts pc          ON pc.person_id = p.id
LEFT JOIN comment_counts cc       ON cc.person_id = p.id
LEFT JOIN likes_post_counts lpc   ON lpc.person_id = p.id
LEFT JOIN likes_comment_counts lcc ON lcc.person_id = p.id
LEFT JOIN friend_counts fc        ON fc.person_id = p.id
LEFT JOIN interest_counts ic      ON ic.person_id = p.id
ORDER BY total_activity DESC
LIMIT 100

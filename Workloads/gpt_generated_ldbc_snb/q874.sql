WITH comment_stats AS (
    SELECT p.id AS person_id,
           COUNT(c.id) AS comment_count,
           AVG(c.length) AS avg_comment_length
    FROM person p
    LEFT JOIN comment c
           ON c.creator_person_id = p.id
    GROUP BY p.id
),
post_stats AS (
    SELECT p.id AS person_id,
           COUNT(po.id) AS post_count,
           AVG(po.length) AS avg_post_length
    FROM person p
    LEFT JOIN post po
           ON po.creator_person_id = p.id
    GROUP BY p.id
),
likes_post_stats AS (
    SELECT p.id AS person_id,
           COUNT(pl.post_id) AS liked_posts
    FROM person p
    LEFT JOIN person_likes_post pl
           ON pl.person_id = p.id
    GROUP BY p.id
),
likes_comment_stats AS (
    SELECT p.id AS person_id,
           COUNT(lc.comment_id) AS liked_comments
    FROM person p
    LEFT JOIN person_likes_comment lc
           ON lc.person_id = p.id
    GROUP BY p.id
),
friend_stats AS (
    SELECT p.id AS person_id,
           COUNT(DISTINCT pk.person2_id) AS friend_count
    FROM person p
    LEFT JOIN person_knows_person pk
           ON pk.person1_id = p.id
    GROUP BY p.id
)
SELECT cs.person_id,
       fs.friend_count,
       cs.comment_count,
       cs.avg_comment_length,
       lps.liked_posts,
       lcs.liked_comments,
       ps.post_count,
       ps.avg_post_length
FROM comment_stats cs
JOIN post_stats ps
     ON cs.person_id = ps.person_id
JOIN likes_post_stats lps
     ON cs.person_id = lps.person_id
JOIN likes_comment_stats lcs
     ON cs.person_id = lcs.person_id
JOIN friend_stats fs
     ON cs.person_id = fs.person_id
ORDER BY cs.comment_count DESC
LIMIT 10

WITH friends AS (
    SELECT person1_id AS person_id, person2_id AS friend_id FROM person_knows_person
    UNION
    SELECT person2_id AS person_id, person1_id AS friend_id FROM person_knows_person
),
friend_counts AS (
    SELECT p.id AS person_id,
           COUNT(DISTINCT f.friend_id) AS total_friends
    FROM person p
    LEFT JOIN friends f ON f.person_id = p.id
    GROUP BY p.id
),
post_stats AS (
    SELECT p.id AS person_id,
           COUNT(DISTINCT po.id) AS post_cnt,
           AVG(po.length) AS avg_post_len
    FROM person p
    LEFT JOIN post po ON po.creator_person_id = p.id
    GROUP BY p.id
),
comment_stats AS (
    SELECT p.id AS person_id,
           COUNT(DISTINCT c.id) AS comment_cnt,
           AVG(c.length) AS avg_comment_len
    FROM person p
    LEFT JOIN comment c ON c.creator_person_id = p.id
    GROUP BY p.id
),
liked_post_counts AS (
    SELECT p.id AS person_id,
           COUNT(DISTINCT plp.post_id) AS liked_post_cnt
    FROM person p
    LEFT JOIN person_likes_post plp ON plp.person_id = p.id
    GROUP BY p.id
),
liked_comment_counts AS (
    SELECT p.id AS person_id,
           COUNT(DISTINCT plc.comment_id) AS liked_comment_cnt
    FROM person p
    LEFT JOIN person_likes_comment plc ON plc.person_id = p.id
    GROUP BY p.id
),
interest_stats AS (
    SELECT p.id AS person_id,
           COUNT(DISTINCT pit.tag_id) AS interest_tag_cnt
    FROM person p
    LEFT JOIN person_has_interest_tag pit ON pit.person_id = p.id
    GROUP BY p.id
),
work_stats AS (
    SELECT p.id AS person_id,
           COUNT(DISTINCT pwc.company_id) AS company_cnt
    FROM person p
    LEFT JOIN person_work_at_company pwc ON pwc.person_id = p.id
    GROUP BY p.id
)
SELECT
    p.id,
    p.first_name,
    p.last_name,
    p.gender,
    p.birthday,
    COALESCE(fc.total_friends, 0) AS total_friends,
    COALESCE(ps.post_cnt, 0) AS post_count,
    ROUND(COALESCE(ps.avg_post_len, 0), 2) AS avg_post_length,
    COALESCE(cs.comment_cnt, 0) AS comment_count,
    ROUND(COALESCE(cs.avg_comment_len, 0), 2) AS avg_comment_length,
    COALESCE(lpc.liked_post_cnt, 0) AS liked_posts,
    COALESCE(lcc.liked_comment_cnt, 0) AS liked_comments,
    COALESCE(ints.interest_tag_cnt, 0) AS interest_tags,
    COALESCE(ws.company_cnt, 0) AS companies_worked_for
FROM person p
LEFT JOIN friend_counts fc   ON fc.person_id = p.id
LEFT JOIN post_stats ps      ON ps.person_id = p.id
LEFT JOIN comment_stats cs   ON cs.person_id = p.id
LEFT JOIN liked_post_counts lpc   ON lpc.person_id = p.id
LEFT JOIN liked_comment_counts lcc ON lcc.person_id = p.id
LEFT JOIN interest_stats ints ON ints.person_id = p.id
LEFT JOIN work_stats ws      ON ws.person_id = p.id
ORDER BY total_friends DESC, post_count DESC
LIMIT 100

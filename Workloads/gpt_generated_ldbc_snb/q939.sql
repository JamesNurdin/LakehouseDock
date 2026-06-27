WITH member_counts AS (
    SELECT forum_has_member_person.forum_id AS forum_id,
           COUNT(DISTINCT forum_has_member_person.person_id) AS member_count
    FROM forum_has_member_person
    GROUP BY forum_has_member_person.forum_id
),
post_stats AS (
    SELECT post.container_forum_id AS forum_id,
           COUNT(*) AS post_count,
           AVG(post.length) AS avg_post_length
    FROM post
    GROUP BY post.container_forum_id
),
likes_stats AS (
    SELECT post.container_forum_id AS forum_id,
           COUNT(person_likes_post.person_id) AS total_likes,
           COUNT(DISTINCT person_likes_post.person_id) AS distinct_likers
    FROM post
    JOIN person_likes_post ON person_likes_post.post_id = post.id
    GROUP BY post.container_forum_id
),
friendship_stats AS (
    SELECT f.id AS forum_id,
           COUNT(*) AS member_friendships
    FROM person_knows_person pk
    JOIN person p1 ON p1.id = pk.person1_id
    JOIN forum_has_member_person fm1 ON fm1.person_id = p1.id
    JOIN forum f ON f.id = fm1.forum_id
    JOIN person p2 ON p2.id = pk.person2_id
    JOIN forum_has_member_person fm2 ON fm2.person_id = p2.id AND fm2.forum_id = f.id
    GROUP BY f.id
)
SELECT f.id,
       f.title,
       f.creation_date,
       COALESCE(m.member_count, 0) AS member_count,
       COALESCE(p.post_count, 0) AS post_count,
       p.avg_post_length,
       COALESCE(l.total_likes, 0) AS total_likes,
       COALESCE(l.distinct_likers, 0) AS distinct_likers,
       COALESCE(fr.member_friendships, 0) AS member_friendships
FROM forum AS f
LEFT JOIN member_counts AS m ON m.forum_id = f.id
LEFT JOIN post_stats AS p ON p.forum_id = f.id
LEFT JOIN likes_stats AS l ON l.forum_id = f.id
LEFT JOIN friendship_stats AS fr ON fr.forum_id = f.id
ORDER BY member_count DESC
LIMIT 10

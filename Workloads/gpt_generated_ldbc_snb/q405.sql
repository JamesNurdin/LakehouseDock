-- For each person, count how many of their friends liked comments that are tagged with a tag belonging to the 'Science' tag class,
-- and compute the total number of such liked comments and the average comment length.
WITH science_friend_likes AS (
    SELECT
        p.id AS person_id,
        p.first_name,
        p.last_name,
        pk.person2_id AS friend_id,
        c.id AS comment_id,
        c.length AS comment_length
    FROM person p
    JOIN person_knows_person pk
        ON pk.person1_id = p.id
    JOIN person_likes_comment plc
        ON plc.person_id = pk.person2_id
    JOIN comment c
        ON c.id = plc.comment_id
    JOIN comment_has_tag_tag cht
        ON cht.comment_id = c.id
    JOIN tag t
        ON t.id = cht.tag_id
    JOIN tag_class tc
        ON tc.id = t.type_tag_class_id
    WHERE tc.name = 'Science'
)
SELECT
    person_id,
    first_name,
    last_name,
    COUNT(DISTINCT friend_id) AS distinct_friends_who_liked,
    COUNT(comment_id) AS total_liked_comments,
    AVG(comment_length) AS avg_comment_length
FROM science_friend_likes
GROUP BY person_id, first_name, last_name
ORDER BY total_liked_comments DESC
LIMIT 20

/*
   Analytical query: For each tag class, compute the total number of "friend" likes
   (likes coming from a person who is directly connected to the content creator) on
   posts and comments that are tagged with that class. Only consider content created
   by persons who work at organisations of type 'Company' located in a place of type
   'Country'. The result shows the top 10 tag classes by total friend‑likes, together
   with the average content length and the number of distinct content items.
*/
WITH filtered_persons AS (
    -- Persons who work at a Company located in a Country
    SELECT p.id AS person_id
    FROM person p
    JOIN person_work_at_company pwac ON pwac.person_id = p.id
    JOIN organisation o ON pwac.company_id = o.id
    JOIN place pl ON o.location_place_id = pl.id
    WHERE o.type = 'Company' AND pl.type = 'Country'
),
post_likes AS (
    -- Likes on posts, counting only those from friends of the creator
    SELECT 
        tc.id AS tag_class_id,
        p.length AS content_length,
        COUNT(pk.person1_id) AS like_count
    FROM post p
    JOIN filtered_persons fp ON p.creator_person_id = fp.person_id
    JOIN post_has_tag_tag pht ON pht.post_id = p.id
    JOIN tag t ON pht.tag_id = t.id
    JOIN tag_class tc ON t.type_tag_class_id = tc.id
    LEFT JOIN person_likes_post plp ON plp.post_id = p.id
    LEFT JOIN person liker ON plp.person_id = liker.id
    LEFT JOIN person_knows_person pk ON (
        (pk.person1_id = fp.person_id AND pk.person2_id = liker.id) OR
        (pk.person1_id = liker.id AND pk.person2_id = fp.person_id)
    )
    GROUP BY tc.id, p.length
),
comment_likes AS (
    -- Likes on comments, counting only those from friends of the creator
    SELECT 
        tc.id AS tag_class_id,
        c.length AS content_length,
        COUNT(pk.person1_id) AS like_count
    FROM comment c
    JOIN filtered_persons fp ON c.creator_person_id = fp.person_id
    JOIN comment_has_tag_tag cht ON cht.comment_id = c.id
    JOIN tag t ON cht.tag_id = t.id
    JOIN tag_class tc ON t.type_tag_class_id = tc.id
    LEFT JOIN person_likes_comment plc ON plc.comment_id = c.id
    LEFT JOIN person liker ON plc.person_id = liker.id
    LEFT JOIN person_knows_person pk ON (
        (pk.person1_id = fp.person_id AND pk.person2_id = liker.id) OR
        (pk.person1_id = liker.id AND pk.person2_id = fp.person_id)
    )
    GROUP BY tc.id, c.length
),
combined AS (
    SELECT * FROM post_likes
    UNION ALL
    SELECT * FROM comment_likes
)
SELECT 
    tc.id AS tag_class_id,
    tc.name AS tag_class_name,
    SUM(c.like_count) AS total_likes,
    AVG(c.content_length) AS avg_content_length,
    COUNT(*) AS content_items
FROM combined c
JOIN tag_class tc ON c.tag_class_id = tc.id
GROUP BY tc.id, tc.name
ORDER BY total_likes DESC
LIMIT 10

WITH friend_likes AS (
    SELECT
        f.id AS forum_id,
        f.title AS forum_title,
        mod.id AS moderator_id,
        mod.first_name AS moderator_first_name,
        mod.last_name AS moderator_last_name,
        friend.id AS friend_id,
        c.id AS comment_id,
        c.length AS comment_length,
        plc.person_id AS liker_id
    FROM forum f
    JOIN person mod ON f.moderator_person_id = mod.id
    JOIN person_knows_person kp ON kp.person1_id = mod.id
    JOIN person friend ON kp.person2_id = friend.id
    JOIN person_has_interest_tag pht ON pht.person_id = friend.id
    JOIN comment c ON c.creator_person_id = friend.id
    JOIN person_likes_comment plc ON plc.comment_id = c.id
    WHERE pht.tag_id = 42
)
SELECT
    forum_id,
    forum_title,
    moderator_id,
    moderator_first_name,
    moderator_last_name,
    COUNT(liker_id) AS total_comment_likes,
    COUNT(DISTINCT comment_id) AS total_comments_by_friends,
    COUNT(DISTINCT friend_id) AS distinct_friends_who_commented,
    AVG(comment_length) AS avg_comment_length
FROM friend_likes
GROUP BY forum_id, forum_title, moderator_id, moderator_first_name, moderator_last_name
ORDER BY total_comment_likes DESC
LIMIT 10

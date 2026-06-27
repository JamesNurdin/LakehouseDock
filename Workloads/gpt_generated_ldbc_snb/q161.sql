/*
  Analytical query: for each forum moderated by a female user, count the distinct friends of the moderator
  who have liked at least one comment and the total number of likes contributed by those friends.
*/
WITH moderator_friends AS (
    SELECT
        f.id AS forum_id,
        f.title AS forum_title,
        m.id AS moderator_id,
        m.first_name AS moderator_first_name,
        m.last_name AS moderator_last_name,
        CASE
            WHEN kp.person1_id = m.id THEN kp.person2_id
            ELSE kp.person1_id
        END AS friend_id
    FROM forum f
    JOIN person m
        ON f.moderator_person_id = m.id
    JOIN person_knows_person kp
        ON kp.person1_id = m.id OR kp.person2_id = m.id
    WHERE m.gender = 'female'
)
SELECT
    mf.forum_id,
    mf.forum_title,
    mf.moderator_id,
    mf.moderator_first_name,
    mf.moderator_last_name,
    COUNT(DISTINCT mf.friend_id) AS distinct_friend_liker_count,
    COUNT(plc.comment_id) AS total_likes_by_friends
FROM moderator_friends mf
JOIN person_likes_comment plc
    ON plc.person_id = mf.friend_id
GROUP BY
    mf.forum_id,
    mf.forum_title,
    mf.moderator_id,
    mf.moderator_first_name,
    mf.moderator_last_name
ORDER BY distinct_friend_liker_count DESC, mf.forum_id

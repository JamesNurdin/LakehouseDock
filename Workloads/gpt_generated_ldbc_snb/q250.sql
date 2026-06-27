WITH forum_members AS (
    SELECT fhmp.forum_id,
           COUNT(DISTINCT fhmp.person_id) AS member_count
    FROM forum_has_member_person fhmp
    GROUP BY fhmp.forum_id
),
forum_posts AS (
    SELECT p.container_forum_id AS forum_id,
           COUNT(*) AS post_count,
           AVG(p.length) AS avg_post_length
    FROM post p
    GROUP BY p.container_forum_id
),
forum_post_tags AS (
    SELECT p.container_forum_id AS forum_id,
           COUNT(DISTINCT pt.tag_id) AS post_tag_count
    FROM post p
    JOIN post_has_tag_tag pt ON pt.post_id = p.id
    GROUP BY p.container_forum_id
),
forum_comments AS (
    SELECT p.container_forum_id AS forum_id,
           COUNT(DISTINCT c.id) AS comment_count,
           AVG(c.length) AS avg_comment_length
    FROM post p
    JOIN comment c ON c.parent_post_id = p.id
    GROUP BY p.container_forum_id
),
forum_post_likes AS (
    SELECT p.container_forum_id AS forum_id,
           COUNT(*) AS post_like_count
    FROM post p
    JOIN person_likes_post plp ON plp.post_id = p.id
    GROUP BY p.container_forum_id
),
forum_comment_likes AS (
    SELECT p.container_forum_id AS forum_id,
           COUNT(*) AS comment_like_count
    FROM post p
    JOIN comment c ON c.parent_post_id = p.id
    JOIN person_likes_comment plc ON plc.comment_id = c.id
    GROUP BY p.container_forum_id
),
forum_tags AS (
    SELECT fht.forum_id,
           COUNT(DISTINCT fht.tag_id) AS forum_tag_count
    FROM forum_has_tag_tag fht
    GROUP BY fht.forum_id
),
forum_participants AS (
    SELECT f.id AS forum_id,
           COUNT(DISTINCT participant_id) AS participant_count
    FROM (
        SELECT fhmp.forum_id, fhmp.person_id AS participant_id
        FROM forum_has_member_person fhmp
        UNION ALL
        SELECT f.id, f.moderator_person_id
        FROM forum f
        UNION ALL
        SELECT p.container_forum_id, p.creator_person_id
        FROM post p
        UNION ALL
        SELECT p.container_forum_id, plp.person_id
        FROM post p
        JOIN person_likes_post plp ON plp.post_id = p.id
        UNION ALL
        SELECT p.container_forum_id, plc.person_id
        FROM post p
        JOIN comment c ON c.parent_post_id = p.id
        JOIN person_likes_comment plc ON plc.comment_id = c.id
        UNION ALL
        SELECT p.container_forum_id, c.creator_person_id
        FROM post p
        JOIN comment c ON c.parent_post_id = p.id
    ) participants
    JOIN forum f ON participants.forum_id = f.id
    GROUP BY f.id
)
SELECT f.id AS forum_id,
       f.title,
       f.creation_date,
       COALESCE(fm.member_count, 0)          AS member_count,
       COALESCE(fp.post_count, 0)            AS post_count,
       COALESCE(fc.comment_count, 0)         AS comment_count,
       COALESCE(fpl.post_like_count, 0)      AS post_like_count,
       COALESCE(fcl.comment_like_count, 0)   AS comment_like_count,
       COALESCE(fp.avg_post_length, 0)       AS avg_post_length,
       COALESCE(fc.avg_comment_length, 0)    AS avg_comment_length,
       COALESCE(ftpt.post_tag_count, 0)      AS post_tag_count,
       COALESCE(ft.forum_tag_count, 0)       AS forum_tag_count,
       COALESCE(fppt.participant_count, 0)   AS participant_count
FROM forum f
LEFT JOIN forum_members fm          ON fm.forum_id = f.id
LEFT JOIN forum_posts fp            ON fp.forum_id = f.id
LEFT JOIN forum_comments fc        ON fc.forum_id = f.id
LEFT JOIN forum_post_likes fpl      ON fpl.forum_id = f.id
LEFT JOIN forum_comment_likes fcl   ON fcl.forum_id = f.id
LEFT JOIN forum_post_tags ftpt      ON ftpt.forum_id = f.id
LEFT JOIN forum_tags ft             ON ft.forum_id = f.id
LEFT JOIN forum_participants fppt   ON fppt.forum_id = f.id
ORDER BY f.id

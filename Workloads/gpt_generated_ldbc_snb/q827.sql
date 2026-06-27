WITH
    forum_members AS (
        SELECT f.id AS forum_id,
               COUNT(DISTINCT fm.person_id) AS member_count
        FROM forum f
        JOIN forum_has_member_person fm
          ON fm.forum_id = f.id
        GROUP BY f.id
    ),
    forum_posts AS (
        SELECT f.id AS forum_id,
               COUNT(DISTINCT p.id) AS post_count,
               AVG(p.length) AS avg_post_length
        FROM forum f
        JOIN post p
          ON p.container_forum_id = f.id
        GROUP BY f.id
    ),
    forum_post_likes AS (
        SELECT f.id AS forum_id,
               COUNT(plp.person_id) AS total_post_likes
        FROM forum f
        JOIN post p
          ON p.container_forum_id = f.id
        JOIN person_likes_post plp
          ON plp.post_id = p.id
        GROUP BY f.id
    ),
    forum_comments AS (
        SELECT f.id AS forum_id,
               COUNT(DISTINCT c.id) AS comment_count,
               AVG(c.length) AS avg_comment_length
        FROM forum f
        JOIN post p
          ON p.container_forum_id = f.id
        JOIN comment c
          ON c.parent_post_id = p.id
        GROUP BY f.id
    ),
    forum_comment_likes AS (
        SELECT f.id AS forum_id,
               COUNT(plc.person_id) AS total_comment_likes
        FROM forum f
        JOIN post p
          ON p.container_forum_id = f.id
        JOIN comment c
          ON c.parent_post_id = p.id
        JOIN person_likes_comment plc
          ON plc.comment_id = c.id
        GROUP BY f.id
    ),
    forum_tags AS (
        SELECT f.id AS forum_id,
               COUNT(DISTINCT pt.tag_id) AS distinct_tag_count
        FROM forum f
        JOIN post p
          ON p.container_forum_id = f.id
        JOIN post_has_tag_tag pt
          ON pt.post_id = p.id
        GROUP BY f.id
    ),
    forum_participants AS (
        SELECT forum_id,
               COUNT(DISTINCT participant_id) AS participant_count
        FROM (
            SELECT f.id AS forum_id,
                   p.creator_person_id AS participant_id
            FROM forum f
            JOIN post p
              ON p.container_forum_id = f.id
            UNION ALL
            SELECT f.id,
                   c.creator_person_id
            FROM forum f
            JOIN post p
              ON p.container_forum_id = f.id
            JOIN comment c
              ON c.parent_post_id = p.id
            UNION ALL
            SELECT f.id,
                   plp.person_id
            FROM forum f
            JOIN post p
              ON p.container_forum_id = f.id
            JOIN person_likes_post plp
              ON plp.post_id = p.id
            UNION ALL
            SELECT f.id,
                   plc.person_id
            FROM forum f
            JOIN post p
              ON p.container_forum_id = f.id
            JOIN comment c
              ON c.parent_post_id = p.id
            JOIN person_likes_comment plc
              ON plc.comment_id = c.id
        ) t
        GROUP BY forum_id
    )
SELECT f.id AS forum_id,
       f.title,
       f.creation_date,
       COALESCE(fm.member_count, 0)               AS member_count,
       COALESCE(fp.post_count, 0)                AS post_count,
       COALESCE(fp.avg_post_length, 0)           AS avg_post_length,
       COALESCE(fc.comment_count, 0)             AS comment_count,
       COALESCE(fc.avg_comment_length, 0)        AS avg_comment_length,
       COALESCE(fpl.total_post_likes, 0)         AS total_post_likes,
       COALESCE(fcl.total_comment_likes, 0)      AS total_comment_likes,
       COALESCE(ft.distinct_tag_count, 0)        AS distinct_tag_count,
       COALESCE(fp2.participant_count, 0)        AS participant_count
FROM forum f
LEFT JOIN forum_members fm          ON fm.forum_id = f.id
LEFT JOIN forum_posts fp            ON fp.forum_id = f.id
LEFT JOIN forum_post_likes fpl      ON fpl.forum_id = f.id
LEFT JOIN forum_comments fc        ON fc.forum_id = f.id
LEFT JOIN forum_comment_likes fcl   ON fcl.forum_id = f.id
LEFT JOIN forum_tags ft             ON ft.forum_id = f.id
LEFT JOIN forum_participants fp2    ON fp2.forum_id = f.id
ORDER BY f.id

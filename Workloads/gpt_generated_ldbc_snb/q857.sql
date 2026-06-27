WITH forum_moderator AS (
    SELECT f.id AS forum_id,
           f.title,
           concat(p.first_name, ' ', p.last_name) AS moderator_name
    FROM forum f
    JOIN person p
      ON f.moderator_person_id = p.id
),
forum_posts AS (
    SELECT p.container_forum_id AS forum_id,
           COUNT(*) AS total_posts,
           AVG(p.length) AS avg_post_length
    FROM post p
    GROUP BY p.container_forum_id
),
forum_likes AS (
    SELECT p.container_forum_id AS forum_id,
           COUNT(*) AS total_likes
    FROM post p
    JOIN person_likes_post plp
      ON plp.post_id = p.id
    GROUP BY p.container_forum_id
),
forum_members AS (
    SELECT fhmp.forum_id,
           COUNT(DISTINCT fhmp.person_id) AS member_count
    FROM forum_has_member_person fhmp
    GROUP BY fhmp.forum_id
),
forum_tags AS (
    SELECT fht.forum_id,
           COUNT(DISTINCT fht.tag_id) AS tag_count
    FROM forum_has_tag_tag fht
    GROUP BY fht.forum_id
)
SELECT fm.forum_id,
       fm.title,
       fm.moderator_name,
       COALESCE(fp.total_posts, 0)                       AS total_posts,
       COALESCE(fl.total_likes, 0)                       AS total_likes,
       COALESCE(fp.avg_post_length, 0)                  AS avg_post_length,
       COALESCE(fmbr.member_count, 0)                   AS member_count,
       COALESCE(ftg.tag_count, 0)                       AS tag_count,
       CASE WHEN COALESCE(fp.total_posts, 0) > 0
            THEN COALESCE(fl.total_likes, 0) / COALESCE(fp.total_posts, 1)
            ELSE 0
       END                                               AS avg_likes_per_post
FROM forum_moderator fm
LEFT JOIN forum_posts fp   ON fm.forum_id = fp.forum_id
LEFT JOIN forum_likes fl   ON fm.forum_id = fl.forum_id
LEFT JOIN forum_members fmbr ON fm.forum_id = fmbr.forum_id
LEFT JOIN forum_tags ftg   ON fm.forum_id = ftg.forum_id
ORDER BY total_posts DESC
LIMIT 10

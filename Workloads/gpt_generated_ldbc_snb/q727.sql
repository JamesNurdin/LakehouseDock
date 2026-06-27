WITH person_friends AS (
    SELECT p.id AS person_id,
           COUNT(DISTINCT kp.person2_id) AS friend_count
    FROM person p
    LEFT JOIN person_knows_person kp ON kp.person1_id = p.id
    GROUP BY p.id
),
person_posts AS (
    SELECT p.id AS person_id,
           COUNT(pst.id) AS post_count,
           AVG(pst.length) AS avg_post_length,
           SUM(COALESCE(like_post.like_cnt, 0)) AS post_likes_received
    FROM person p
    LEFT JOIN post pst ON pst.creator_person_id = p.id
    LEFT JOIN (
        SELECT plp.post_id,
               COUNT(*) AS like_cnt
        FROM person_likes_post plp
        GROUP BY plp.post_id
    ) like_post ON like_post.post_id = pst.id
    GROUP BY p.id
),
person_comments AS (
    SELECT p.id AS person_id,
           COUNT(cmt.id) AS comment_count,
           AVG(cmt.length) AS avg_comment_length,
           SUM(COALESCE(like_comment.like_cnt, 0)) AS comment_likes_received
    FROM person p
    LEFT JOIN comment cmt ON cmt.creator_person_id = p.id
    LEFT JOIN (
        SELECT plc.comment_id,
               COUNT(*) AS like_cnt
        FROM person_likes_comment plc
        GROUP BY plc.comment_id
    ) like_comment ON like_comment.comment_id = cmt.id
    GROUP BY p.id
),
person_likes_given AS (
    SELECT p.id AS person_id,
           COUNT(DISTINCT plp.post_id) AS post_likes_given,
           COUNT(DISTINCT plc.comment_id) AS comment_likes_given
    FROM person p
    LEFT JOIN person_likes_post plp ON plp.person_id = p.id
    LEFT JOIN person_likes_comment plc ON plc.person_id = p.id
    GROUP BY p.id
),
person_forum_membership AS (
    SELECT p.id AS person_id,
           COUNT(DISTINCT fmp.forum_id) AS forum_membership_count,
           COUNT(DISTINCT f.id) FILTER (WHERE f.moderator_person_id = p.id) AS forum_moderated_count
    FROM person p
    LEFT JOIN forum_has_member_person fmp ON fmp.person_id = p.id
    LEFT JOIN forum f ON f.id = fmp.forum_id
    GROUP BY p.id
),
person_interests AS (
    SELECT p.id AS person_id,
           COUNT(DISTINCT pit.tag_id) AS interest_tag_count,
           COUNT(DISTINCT fht.tag_id) AS forum_member_tag_count
    FROM person p
    LEFT JOIN person_has_interest_tag pit ON pit.person_id = p.id
    LEFT JOIN forum_has_member_person fmp ON fmp.person_id = p.id
    LEFT JOIN forum_has_tag_tag fht ON fht.forum_id = fmp.forum_id
    GROUP BY p.id
)
SELECT p.id,
       p.first_name,
       p.last_name,
       COALESCE(pf.friend_count, 0) AS friend_count,
       COALESCE(pp.post_count, 0) AS post_count,
       COALESCE(pc.comment_count, 0) AS comment_count,
       COALESCE(plg.post_likes_given, 0) AS post_likes_given,
       COALESCE(plg.comment_likes_given, 0) AS comment_likes_given,
       COALESCE(pp.avg_post_length, 0) AS avg_post_length,
       COALESCE(pc.avg_comment_length, 0) AS avg_comment_length,
       COALESCE(pp.post_likes_received, 0) AS post_likes_received,
       COALESCE(pc.comment_likes_received, 0) AS comment_likes_received,
       COALESCE(pfm.forum_membership_count, 0) AS forum_membership_count,
       COALESCE(pfm.forum_moderated_count, 0) AS forum_moderated_count,
       COALESCE(pi.interest_tag_count, 0) AS interest_tag_count,
       COALESCE(pi.forum_member_tag_count, 0) AS forum_member_tag_count
FROM person p
LEFT JOIN person_friends pf ON pf.person_id = p.id
LEFT JOIN person_posts pp ON pp.person_id = p.id
LEFT JOIN person_comments pc ON pc.person_id = p.id
LEFT JOIN person_likes_given plg ON plg.person_id = p.id
LEFT JOIN person_forum_membership pfm ON pfm.person_id = p.id
LEFT JOIN person_interests pi ON pi.person_id = p.id
ORDER BY p.id
LIMIT 100

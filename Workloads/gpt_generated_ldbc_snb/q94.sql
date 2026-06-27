WITH forum_posts AS (
    SELECT f.id AS forum_id,
           f.title AS forum_title,
           p.id AS post_id
    FROM forum f
    JOIN post p
      ON p.container_forum_id = f.id
),

forum_posts_agg AS (
    SELECT forum_id,
           forum_title,
           COUNT(DISTINCT post_id) AS post_count
    FROM forum_posts
    GROUP BY forum_id, forum_title
),

forum_comments AS (
    SELECT fp.forum_id,
           c.id AS comment_id,
           c.length AS comment_length,
           c.creator_person_id AS commenter_id
    FROM forum_posts fp
    JOIN comment c
      ON c.parent_post_id = fp.post_id
),

forum_comments_agg AS (
    SELECT forum_id,
           COUNT(DISTINCT comment_id) AS comment_count,
           AVG(comment_length) AS avg_comment_length,
           COUNT(DISTINCT commenter_id) AS distinct_commenters
    FROM forum_comments
    GROUP BY forum_id
),

forum_likes AS (
    SELECT fc.forum_id,
           plc.person_id AS liker_id,
           plc.comment_id AS liked_comment_id
    FROM forum_comments fc
    JOIN person_likes_comment plc
      ON plc.comment_id = fc.comment_id
),

forum_likes_agg AS (
    SELECT forum_id,
           COUNT(*) AS like_count
    FROM forum_likes
    GROUP BY forum_id
),

forum_members AS (
    SELECT f.id AS forum_id,
           fm.person_id AS member_id
    FROM forum f
    JOIN forum_has_member_person fm
      ON fm.forum_id = f.id
),

forum_members_agg AS (
    SELECT forum_id,
           COUNT(DISTINCT member_id) AS member_count
    FROM forum_members
    GROUP BY forum_id
),

forum_member_interests AS (
    SELECT fm.forum_id,
           phi.tag_id AS interest_tag_id
    FROM forum_has_member_person fm
    JOIN person p
      ON p.id = fm.person_id
    JOIN person_has_interest_tag phi
      ON phi.person_id = p.id
),

forum_member_interests_agg AS (
    SELECT forum_id,
           COUNT(DISTINCT interest_tag_id) AS distinct_member_interests
    FROM forum_member_interests
    GROUP BY forum_id
),

forum_comment_tags AS (
    SELECT fc.forum_id,
           cht.tag_id AS comment_tag_id
    FROM forum_comments fc
    JOIN comment_has_tag_tag cht
      ON cht.comment_id = fc.comment_id
),

forum_comment_tags_agg AS (
    SELECT forum_id,
           COUNT(DISTINCT comment_tag_id) AS distinct_comment_tags
    FROM forum_comment_tags
    GROUP BY forum_id
)

SELECT fpag.forum_id,
       fpag.forum_title,
       fpag.post_count,
       fca.comment_count,
       fca.avg_comment_length,
       fca.distinct_commenters,
       fla.like_count,
       fma.member_count,
       fmi.distinct_member_interests,
       fct.distinct_comment_tags
FROM forum_posts_agg fpag
LEFT JOIN forum_comments_agg fca
  ON fca.forum_id = fpag.forum_id
LEFT JOIN forum_likes_agg fla
  ON fla.forum_id = fpag.forum_id
LEFT JOIN forum_members_agg fma
  ON fma.forum_id = fpag.forum_id
LEFT JOIN forum_member_interests_agg fmi
  ON fmi.forum_id = fpag.forum_id
LEFT JOIN forum_comment_tags_agg fct
  ON fct.forum_id = fpag.forum_id
ORDER BY fpag.post_count DESC
LIMIT 100

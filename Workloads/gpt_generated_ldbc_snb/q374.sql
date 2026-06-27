WITH forum_posts AS (
    SELECT f.id AS forum_id,
           f.title AS forum_title,
           p.id AS post_id,
           p.length AS post_length,
           p.creator_person_id AS post_creator_id
    FROM forum f
    LEFT JOIN post p ON p.container_forum_id = f.id
),
posts_agg AS (
    SELECT forum_id,
           forum_title,
           COUNT(DISTINCT post_id) AS num_posts,
           COALESCE(SUM(post_length), 0) AS total_post_length,
           CASE WHEN COUNT(DISTINCT post_id) > 0
                THEN SUM(post_length) * 1.0 / COUNT(DISTINCT post_id)
                ELSE 0
           END AS avg_post_length,
           COUNT(DISTINCT post_creator_id) AS num_unique_post_creators
    FROM forum_posts
    GROUP BY forum_id, forum_title
),
forum_comments AS (
    SELECT fp.forum_id,
           c.id AS comment_id,
           c.creator_person_id AS comment_creator_id
    FROM forum_posts fp
    LEFT JOIN comment c ON c.parent_post_id = fp.post_id
),
comments_agg AS (
    SELECT forum_id,
           COUNT(DISTINCT comment_id) AS num_comments,
           COUNT(DISTINCT comment_creator_id) AS num_unique_commenters
    FROM forum_comments
    GROUP BY forum_id
),
forum_members AS (
    SELECT fm.forum_id,
           fm.person_id AS member_person_id
    FROM forum_has_member_person fm
),
members_agg AS (
    SELECT forum_id,
           COUNT(DISTINCT member_person_id) AS num_members
    FROM forum_members
    GROUP BY forum_id
),
post_tags AS (
    SELECT fp.forum_id,
           pt.tag_id
    FROM forum_posts fp
    LEFT JOIN post_has_tag_tag pt ON pt.post_id = fp.post_id
),
tags_agg AS (
    SELECT forum_id,
           COUNT(DISTINCT tag_id) AS num_distinct_tags
    FROM post_tags
    GROUP BY forum_id
),
top_tag_per_forum AS (
    SELECT pt.forum_id,
           t.name AS top_tag_name
    FROM (
        SELECT forum_id,
               tag_id,
               COUNT(*) AS tag_cnt,
               ROW_NUMBER() OVER (PARTITION BY forum_id ORDER BY COUNT(*) DESC) AS rn
        FROM post_tags
        GROUP BY forum_id, tag_id
    ) pt
    LEFT JOIN tag t ON t.id = pt.tag_id
    WHERE pt.rn = 1
)
SELECT p.forum_id,
       p.forum_title,
       p.num_posts,
       p.total_post_length,
       p.avg_post_length,
       p.num_unique_post_creators,
       COALESCE(c.num_comments, 0) AS num_comments,
       COALESCE(c.num_unique_commenters, 0) AS num_unique_commenters,
       COALESCE(m.num_members, 0) AS num_members,
       COALESCE(t.num_distinct_tags, 0) AS num_distinct_tags,
       tt.top_tag_name
FROM posts_agg p
LEFT JOIN comments_agg c ON c.forum_id = p.forum_id
LEFT JOIN members_agg m ON m.forum_id = p.forum_id
LEFT JOIN tags_agg t ON t.forum_id = p.forum_id
LEFT JOIN top_tag_per_forum tt ON tt.forum_id = p.forum_id
ORDER BY p.num_posts DESC
LIMIT 100

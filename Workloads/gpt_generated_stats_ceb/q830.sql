WITH user_posts AS (
    SELECT owneruserid AS userid,
           count(*) AS post_count,
           sum(score) AS total_post_score,
           sum(viewcount) AS total_views,
           sum(answercount) AS total_answers,
           sum(commentcount) AS total_comments_on_posts,
           sum(favoritecount) AS total_favorites
    FROM posts
    GROUP BY owneruserid
),
user_edits AS (
    SELECT lasteditoruserid AS userid,
           count(*) AS edit_count
    FROM posts
    WHERE lasteditoruserid IS NOT NULL
    GROUP BY lasteditoruserid
),
user_comments AS (
    SELECT userid,
           count(*) AS comment_count,
           sum(score) AS total_comment_score
    FROM comments
    GROUP BY userid
),
user_votes AS (
    SELECT userid,
           count(*) AS vote_count,
           sum(CASE WHEN votetypeid = 1 THEN 1 ELSE 0 END) AS upvote_count,
           sum(CASE WHEN votetypeid = 2 THEN 1 ELSE 0 END) AS downvote_count
    FROM votes
    GROUP BY userid
),
user_badges AS (
    SELECT userid,
           count(*) AS badge_count
    FROM badges
    GROUP BY userid
),
user_posthistory AS (
    SELECT userid,
           count(*) AS posthistory_count
    FROM posthistory
    GROUP BY userid
),
user_tag_excerpts AS (
    SELECT p.owneruserid AS userid,
           count(*) AS tag_excerpt_count
    FROM tags t
    JOIN posts p ON t.excerptpostid = p.id
    GROUP BY p.owneruserid
)
SELECT u.id,
       u.reputation,
       u.creationdate,
       u.views,
       u.upvotes,
       u.downvotes,
       coalesce(p.post_count, 0) AS post_count,
       coalesce(p.total_post_score, 0) AS total_post_score,
       coalesce(p.total_views, 0) AS total_views,
       coalesce(p.total_answers, 0) AS total_answers,
       coalesce(p.total_comments_on_posts, 0) AS total_comments_on_posts,
       coalesce(p.total_favorites, 0) AS total_favorites,
       coalesce(e.edit_count, 0) AS edit_count,
       coalesce(c.comment_count, 0) AS comment_count,
       coalesce(c.total_comment_score, 0) AS total_comment_score,
       coalesce(v.vote_count, 0) AS vote_count,
       coalesce(v.upvote_count, 0) AS upvote_count,
       coalesce(v.downvote_count, 0) AS downvote_count,
       coalesce(b.badge_count, 0) AS badge_count,
       coalesce(h.posthistory_count, 0) AS posthistory_count,
       coalesce(t.tag_excerpt_count, 0) AS tag_excerpt_count,
       case when coalesce(p.post_count, 0) > 0 then p.total_post_score / p.post_count else null end AS avg_post_score,
       case when coalesce(c.comment_count, 0) > 0 then c.total_comment_score / c.comment_count else null end AS avg_comment_score
FROM users u
LEFT JOIN user_posts p ON u.id = p.userid
LEFT JOIN user_edits e ON u.id = e.userid
LEFT JOIN user_comments c ON u.id = c.userid
LEFT JOIN user_votes v ON u.id = v.userid
LEFT JOIN user_badges b ON u.id = b.userid
LEFT JOIN user_posthistory h ON u.id = h.userid
LEFT JOIN user_tag_excerpts t ON u.id = t.userid
WHERE u.creationdate >= TIMESTAMP '2020-01-01 00:00:00 UTC'
ORDER BY u.reputation DESC
LIMIT 100

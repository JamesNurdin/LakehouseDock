/*
  Analytical overview per user:
  - Posts authored and their aggregates (score, views, favorites, answers, comments)
  - Votes received on a user's posts (total, up/down, bounty amount)
  - Comments made by the user and their total score
  - Badges earned
  - Post‑history events recorded by the user
  - Number of tag excerpt posts authored (tags whose excerpt post belongs to the user)
  The result is ordered by reputation descending and limited to the top 100 users.
*/
WITH
    user_posts AS (
        SELECT
            p.owneruserid AS user_id,
            COUNT(*) AS post_count,
            SUM(p.score) AS total_post_score,
            SUM(p.viewcount) AS total_view_count,
            SUM(p.favoritecount) AS total_favorite_count,
            SUM(p.answercount) AS total_answer_count,
            SUM(p.commentcount) AS total_comment_count
        FROM posts p
        GROUP BY p.owneruserid
    ),
    user_votes_received AS (
        SELECT
            p.owneruserid AS user_id,
            COUNT(v.id) AS vote_count,
            SUM(CASE WHEN v.bountyamount IS NOT NULL THEN v.bountyamount ELSE 0 END) AS total_bounty_amount,
            COUNT(CASE WHEN v.votetypeid = 2 THEN 1 END) AS upvote_count,
            COUNT(CASE WHEN v.votetypeid = 3 THEN 1 END) AS downvote_count
        FROM votes v
        JOIN posts p ON v.postid = p.id
        GROUP BY p.owneruserid
    ),
    user_comments_made AS (
        SELECT
            c.userid AS user_id,
            COUNT(*) AS comment_made_count,
            SUM(c.score) AS total_comment_score
        FROM comments c
        GROUP BY c.userid
    ),
    user_badges AS (
        SELECT
            b.userid AS user_id,
            COUNT(*) AS badge_count
        FROM badges b
        GROUP BY b.userid
    ),
    user_posthistory AS (
        SELECT
            ph.userid AS user_id,
            COUNT(*) AS posthistory_event_count
        FROM posthistory ph
        GROUP BY ph.userid
    ),
    user_tag_excerpts AS (
        SELECT
            p.owneruserid AS user_id,
            COUNT(*) AS tag_excerpt_count
        FROM tags t
        JOIN posts p ON t.excerptpostid = p.id
        GROUP BY p.owneruserid
    )
SELECT
    u.id AS user_id,
    u.reputation,
    u.creationdate,
    u.views,
    u.upvotes,
    u.downvotes,
    COALESCE(up.post_count, 0) AS post_count,
    COALESCE(up.total_post_score, 0) AS total_post_score,
    COALESCE(up.total_view_count, 0) AS total_view_count,
    COALESCE(up.total_favorite_count, 0) AS total_favorite_count,
    COALESCE(up.total_answer_count, 0) AS total_answer_count,
    COALESCE(up.total_comment_count, 0) AS total_comment_count,
    COALESCE(uv.vote_count, 0) AS vote_received_count,
    COALESCE(uv.total_bounty_amount, 0) AS total_bounty_received,
    COALESCE(uv.upvote_count, 0) AS upvote_received_count,
    COALESCE(uv.downvote_count, 0) AS downvote_received_count,
    COALESCE(uc.comment_made_count, 0) AS comment_made_count,
    COALESCE(uc.total_comment_score, 0) AS total_comment_score,
    COALESCE(ub.badge_count, 0) AS badge_count,
    COALESCE(uph.posthistory_event_count, 0) AS posthistory_event_count,
    COALESCE(ute.tag_excerpt_count, 0) AS tag_excerpt_count
FROM users u
LEFT JOIN user_posts up ON u.id = up.user_id
LEFT JOIN user_votes_received uv ON u.id = uv.user_id
LEFT JOIN user_comments_made uc ON u.id = uc.user_id
LEFT JOIN user_badges ub ON u.id = ub.user_id
LEFT JOIN user_posthistory uph ON u.id = uph.user_id
LEFT JOIN user_tag_excerpts ute ON u.id = ute.user_id
ORDER BY u.reputation DESC
LIMIT 100

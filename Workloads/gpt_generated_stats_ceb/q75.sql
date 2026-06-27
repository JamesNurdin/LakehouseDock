WITH
    user_posts AS (
        SELECT
            p.owneruserid,
            COUNT(*) AS total_posts_owned,
            SUM(p.score) AS total_post_score_owned,
            SUM(p.viewcount) AS total_viewcount_owned,
            SUM(p.answercount) AS total_answercount_owned,
            SUM(p.commentcount) AS total_commentcount_owned,
            SUM(p.favoritecount) AS total_favoritecount_owned
        FROM posts p
        GROUP BY p.owneruserid
    ),
    user_edits AS (
        SELECT
            p.lasteditoruserid,
            COUNT(*) AS total_posts_edited,
            SUM(p.score) AS total_post_score_edited,
            SUM(p.viewcount) AS total_viewcount_edited
        FROM posts p
        GROUP BY p.lasteditoruserid
    ),
    user_comments AS (
        SELECT
            c.userid,
            COUNT(*) AS total_comments_made,
            SUM(c.score) AS total_comment_score_made
        FROM comments c
        GROUP BY c.userid
    ),
    user_votes_cast AS (
        SELECT
            v.userid,
            COUNT(*) AS total_votes_cast,
            SUM(v.bountyamount) AS total_bounty_given
        FROM votes v
        GROUP BY v.userid
    ),
    user_votes_received AS (
        SELECT
            p.owneruserid,
            COUNT(*) AS total_votes_received,
            SUM(v.bountyamount) AS total_bounty_received
        FROM votes v
        JOIN posts p ON v.postid = p.id
        GROUP BY p.owneruserid
    ),
    user_badges AS (
        SELECT
            b.userid,
            COUNT(*) AS total_badges_earned
        FROM badges b
        GROUP BY b.userid
    ),
    user_tags AS (
        SELECT
            p.owneruserid,
            COUNT(DISTINCT t.id) AS distinct_tags_on_owned_posts
        FROM tags t
        JOIN posts p ON t.excerptpostid = p.id
        GROUP BY p.owneruserid
    ),
    user_postlinks_out AS (
        SELECT
            p.owneruserid,
            COUNT(*) AS total_postlinks_out
        FROM postlinks pl
        JOIN posts p ON pl.postid = p.id
        GROUP BY p.owneruserid
    ),
    user_postlinks_in AS (
        SELECT
            p.owneruserid,
            COUNT(*) AS total_postlinks_in
        FROM postlinks pl
        JOIN posts p ON pl.relatedpostid = p.id
        GROUP BY p.owneruserid
    )
SELECT
    u.id AS user_id,
    u.reputation,
    COALESCE(p.total_posts_owned, 0) AS total_posts_owned,
    COALESCE(p.total_post_score_owned, 0) AS total_post_score_owned,
    COALESCE(p.total_viewcount_owned, 0) AS total_viewcount_owned,
    COALESCE(e.total_posts_edited, 0) AS total_posts_edited,
    COALESCE(c.total_comments_made, 0) AS total_comments_made,
    COALESCE(c.total_comment_score_made, 0) AS total_comment_score_made,
    COALESCE(vc.total_votes_cast, 0) AS total_votes_cast,
    COALESCE(vr.total_votes_received, 0) AS total_votes_received,
    COALESCE(b.total_badges_earned, 0) AS total_badges_earned,
    COALESCE(t.distinct_tags_on_owned_posts, 0) AS distinct_tags_on_owned_posts,
    COALESCE(pl_out.total_postlinks_out, 0) AS total_postlinks_out,
    COALESCE(pl_in.total_postlinks_in, 0) AS total_postlinks_in,
    CASE WHEN COALESCE(p.total_posts_owned, 0) = 0 THEN NULL
         ELSE COALESCE(p.total_post_score_owned, 0) * 1.0 / p.total_posts_owned END AS avg_post_score_owned,
    CASE WHEN COALESCE(c.total_comments_made, 0) = 0 THEN NULL
         ELSE COALESCE(c.total_comment_score_made, 0) * 1.0 / c.total_comments_made END AS avg_comment_score_made,
    CASE WHEN COALESCE(p.total_posts_owned, 0) = 0 THEN NULL
         ELSE COALESCE(vr.total_votes_received, 0) * 1.0 / p.total_posts_owned END AS avg_votes_received_per_post
FROM users u
LEFT JOIN user_posts p ON u.id = p.owneruserid
LEFT JOIN user_edits e ON u.id = e.lasteditoruserid
LEFT JOIN user_comments c ON u.id = c.userid
LEFT JOIN user_votes_cast vc ON u.id = vc.userid
LEFT JOIN user_votes_received vr ON u.id = vr.owneruserid
LEFT JOIN user_badges b ON u.id = b.userid
LEFT JOIN user_tags t ON u.id = t.owneruserid
LEFT JOIN user_postlinks_out pl_out ON u.id = pl_out.owneruserid
LEFT JOIN user_postlinks_in pl_in ON u.id = pl_in.owneruserid
ORDER BY u.reputation DESC
LIMIT 100

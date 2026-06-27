WITH user_posts AS (
    SELECT
        p.owneruserid AS owneruserid,
        COUNT(*) AS post_count,
        COALESCE(SUM(p.score), 0) AS post_score_sum,
        COALESCE(SUM(p.viewcount), 0) AS post_viewcount_sum,
        COALESCE(SUM(p.answercount), 0) AS post_answercount_sum,
        COALESCE(SUM(p.commentcount), 0) AS post_commentcount_sum,
        COALESCE(SUM(p.favoritecount), 0) AS post_favoritecount_sum
    FROM posts p
    GROUP BY p.owneruserid
),
user_comments AS (
    SELECT
        c.userid AS userid,
        COUNT(*) AS comment_count,
        COALESCE(SUM(c.score), 0) AS comment_score_sum
    FROM comments c
    GROUP BY c.userid
),
user_badges AS (
    SELECT
        b.userid AS userid,
        COUNT(*) AS badge_count
    FROM badges b
    GROUP BY b.userid
),
user_votes_given AS (
    SELECT
        v.userid AS userid,
        COUNT(*) AS votes_given_count,
        COALESCE(SUM(v.bountyamount), 0) AS bounty_given_sum
    FROM votes v
    GROUP BY v.userid
),
user_votes_received AS (
    SELECT
        p.owneruserid AS owneruserid,
        COUNT(*) AS votes_received_count,
        COALESCE(SUM(v.bountyamount), 0) AS bounty_received_sum
    FROM votes v
    JOIN posts p ON v.postid = p.id
    GROUP BY p.owneruserid
),
user_tags AS (
    SELECT
        p.owneruserid AS owneruserid,
        COUNT(*) AS tag_count
    FROM tags t
    JOIN posts p ON t.excerptpostid = p.id
    GROUP BY p.owneruserid
),
user_postlinks_out AS (
    SELECT
        p.owneruserid AS owneruserid,
        COUNT(*) AS postlink_out_count
    FROM postlinks pl
    JOIN posts p ON pl.postid = p.id
    GROUP BY p.owneruserid
),
user_postlinks_in AS (
    SELECT
        p.owneruserid AS owneruserid,
        COUNT(*) AS postlink_in_count
    FROM postlinks pl
    JOIN posts p ON pl.relatedpostid = p.id
    GROUP BY p.owneruserid
),
user_posthistory_by_user AS (
    SELECT
        ph.userid AS userid,
        COUNT(*) AS posthistory_by_user_count
    FROM posthistory ph
    GROUP BY ph.userid
),
user_posthistory_on_posts AS (
    SELECT
        p.owneruserid AS owneruserid,
        COUNT(*) AS posthistory_on_posts_count
    FROM posthistory ph
    JOIN posts p ON ph.posthistorytypeid = p.id
    GROUP BY p.owneruserid
)
SELECT
    u.id AS user_id,
    u.reputation,
    u.creationdate,
    COALESCE(up.post_count, 0) AS total_posts,
    COALESCE(up.post_score_sum, 0) AS total_post_score,
    COALESCE(up.post_viewcount_sum, 0) AS total_post_views,
    COALESCE(up.post_answercount_sum, 0) AS total_answers,
    COALESCE(up.post_commentcount_sum, 0) AS total_comments_on_posts,
    COALESCE(up.post_favoritecount_sum, 0) AS total_favorites,
    COALESCE(ub.badge_count, 0) AS total_badges,
    COALESCE(uc.comment_count, 0) AS total_comments_made,
    COALESCE(uc.comment_score_sum, 0) AS total_comment_score,
    COALESCE(uvg.votes_given_count, 0) AS total_votes_given,
    COALESCE(uvg.bounty_given_sum, 0) AS total_bounty_given,
    COALESCE(uvr.votes_received_count, 0) AS total_votes_received,
    COALESCE(uvr.bounty_received_sum, 0) AS total_bounty_received,
    COALESCE(ut.tag_count, 0) AS total_tags_used,
    COALESCE(upl_out.postlink_out_count, 0) AS total_postlinks_out,
    COALESCE(upl_in.postlink_in_count, 0) AS total_postlinks_in,
    COALESCE(uphb.posthistory_by_user_count, 0) AS total_posthistory_by_user,
    COALESCE(uphp.posthistory_on_posts_count, 0) AS total_posthistory_on_user_posts
FROM users u
LEFT JOIN user_posts up ON up.owneruserid = u.id
LEFT JOIN user_comments uc ON uc.userid = u.id
LEFT JOIN user_badges ub ON ub.userid = u.id
LEFT JOIN user_votes_given uvg ON uvg.userid = u.id
LEFT JOIN user_votes_received uvr ON uvr.owneruserid = u.id
LEFT JOIN user_tags ut ON ut.owneruserid = u.id
LEFT JOIN user_postlinks_out upl_out ON upl_out.owneruserid = u.id
LEFT JOIN user_postlinks_in upl_in ON upl_in.owneruserid = u.id
LEFT JOIN user_posthistory_by_user uphb ON uphb.userid = u.id
LEFT JOIN user_posthistory_on_posts uphp ON uphp.owneruserid = u.id
ORDER BY total_posts DESC, total_votes_received DESC
LIMIT 100

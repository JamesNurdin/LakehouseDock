WITH post_metrics AS (
    SELECT date_trunc('month', creationdate) AS month,
           count(*) AS post_count,
           avg(score) AS avg_post_score,
           sum(viewcount) AS total_views,
           sum(answercount) AS total_answers,
           sum(commentcount) AS total_comments_on_posts
    FROM posts
    GROUP BY date_trunc('month', creationdate)
),
comment_metrics AS (
    SELECT date_trunc('month', creationdate) AS month,
           count(*) AS comment_count,
           avg(score) AS avg_comment_score,
           count(DISTINCT userid) AS distinct_commenters
    FROM comments
    GROUP BY date_trunc('month', creationdate)
),
vote_metrics AS (
    SELECT date_trunc('month', creationdate) AS month,
           count(*) AS vote_count,
           sum(CASE WHEN votetypeid = 1 THEN 1 ELSE 0 END) AS upvote_count,
           sum(CASE WHEN votetypeid = 2 THEN 1 ELSE 0 END) AS downvote_count,
           sum(bountyamount) AS total_bounty_amount
    FROM votes
    GROUP BY date_trunc('month', creationdate)
),
badge_metrics AS (
    SELECT date_trunc('month', date) AS month,
           count(*) AS badge_count,
           count(DISTINCT userid) AS distinct_badge_recipients
    FROM badges
    GROUP BY date_trunc('month', date)
),
user_metrics AS (
    SELECT date_trunc('month', creationdate) AS month,
           count(*) AS new_user_count,
           avg(reputation) AS avg_reputation_new_users
    FROM users
    GROUP BY date_trunc('month', creationdate)
),
postlink_metrics AS (
    SELECT date_trunc('month', creationdate) AS month,
           count(*) AS postlink_count,
           sum(CASE WHEN linktypeid = 1 THEN 1 ELSE 0 END) AS internal_links,
           sum(CASE WHEN linktypeid = 2 THEN 1 ELSE 0 END) AS external_links
    FROM postlinks
    GROUP BY date_trunc('month', creationdate)
),
posthistory_metrics AS (
    SELECT date_trunc('month', creationdate) AS month,
           count(*) AS posthistory_count,
           count(DISTINCT userid) AS distinct_history_users
    FROM posthistory
    GROUP BY date_trunc('month', creationdate)
)
SELECT pm.month,
       pm.post_count,
       pm.avg_post_score,
       pm.total_views,
       pm.total_answers,
       pm.total_comments_on_posts,
       cm.comment_count,
       cm.avg_comment_score,
       cm.distinct_commenters,
       vm.vote_count,
       vm.upvote_count,
       vm.downvote_count,
       vm.total_bounty_amount,
       bm.badge_count,
       bm.distinct_badge_recipients,
       um.new_user_count,
       um.avg_reputation_new_users,
       plm.postlink_count,
       plm.internal_links,
       plm.external_links,
       phm.posthistory_count,
       phm.distinct_history_users,
       (coalesce(pm.post_count, 0) * 2 + coalesce(cm.comment_count, 0) + coalesce(vm.vote_count, 0) * 0.5) AS activity_score
FROM post_metrics pm
LEFT JOIN comment_metrics cm ON pm.month = cm.month
LEFT JOIN vote_metrics vm ON pm.month = vm.month
LEFT JOIN badge_metrics bm ON pm.month = bm.month
LEFT JOIN user_metrics um ON pm.month = um.month
LEFT JOIN postlink_metrics plm ON pm.month = plm.month
LEFT JOIN posthistory_metrics phm ON pm.month = phm.month
ORDER BY pm.month DESC

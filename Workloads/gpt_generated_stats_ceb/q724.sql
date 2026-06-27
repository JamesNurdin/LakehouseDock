SELECT
    t.id AS tag_id,
    COUNT(DISTINCT p.id) AS num_posts,
    SUM(p.score) AS total_post_score,
    SUM(p.viewcount) AS total_views,
    SUM(p.answercount) AS total_answers,
    SUM(p.commentcount) AS total_comments_on_posts,
    SUM(p.favoritecount) AS total_favorites,
    COUNT(DISTINCT v.id) AS total_votes,
    SUM(COALESCE(v.bountyamount, 0)) AS total_bounty_amount,
    COUNT(DISTINCT c.id) AS total_comments,
    COUNT(DISTINCT ph.id) AS total_post_history_entries,
    COUNT(DISTINCT pl.id) AS total_post_links,
    COUNT(DISTINCT b.id) AS total_owner_badges
FROM tags t
JOIN posts p
    ON t.excerptpostid = p.id
LEFT JOIN votes v
    ON v.postid = p.id
LEFT JOIN comments c
    ON c.postid = p.id
LEFT JOIN posthistory ph
    ON ph.posthistorytypeid = p.id
LEFT JOIN postlinks pl
    ON pl.postid = p.id
LEFT JOIN users u
    ON p.owneruserid = u.id
LEFT JOIN badges b
    ON b.userid = u.id
GROUP BY t.id
ORDER BY total_views DESC
LIMIT 10

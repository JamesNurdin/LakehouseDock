-- Analytical query: post‑level activity summary
-- For each post we compute counts of comments, votes, edits, linked posts, tag excerpts, and owner badges
WITH post_stats AS (
    SELECT
        p.id AS post_id,
        p.posttypeid,
        p.creationdate,
        p.owneruserid,
        u.reputation AS owner_reputation,
        p.score AS post_score,
        p.viewcount,
        COUNT(DISTINCT c.id) AS comment_count,
        COUNT(DISTINCT CASE WHEN v.votetypeid = 2 THEN v.id END) AS upvote_count,
        COUNT(DISTINCT CASE WHEN v.votetypeid = 3 THEN v.id END) AS downvote_count,
        COUNT(DISTINCT ph.id) AS edit_history_count,
        COUNT(DISTINCT pl.id) AS postlink_count,
        COUNT(DISTINCT t.id) AS tag_excerpt_count,
        COUNT(DISTINCT b.id) AS owner_badge_count
    FROM posts p
    LEFT JOIN users u ON u.id = p.owneruserid                       -- posts.owneruserid → users.id
    LEFT JOIN comments c ON c.postid = p.id                         -- comments.postid → posts.id
    LEFT JOIN votes v ON v.postid = p.id                            -- votes.postid → posts.id
    LEFT JOIN posthistory ph ON ph.posthistorytypeid = p.id        -- posthistory.posthistorytypeid → posts.id
    LEFT JOIN postlinks pl ON pl.postid = p.id OR pl.relatedpostid = p.id  -- postlinks.postid / relatedpostid → posts.id
    LEFT JOIN tags t ON t.excerptpostid = p.id                     -- tags.excerptpostid → posts.id
    LEFT JOIN badges b ON b.userid = u.id                           -- badges.userid → users.id
    GROUP BY p.id, p.posttypeid, p.creationdate, p.owneruserid, u.reputation, p.score, p.viewcount
)
SELECT
    post_id,
    posttypeid,
    creationdate,
    owneruserid,
    owner_reputation,
    post_score,
    viewcount,
    comment_count,
    upvote_count,
    downvote_count,
    edit_history_count,
    postlink_count,
    tag_excerpt_count,
    owner_badge_count
FROM post_stats
ORDER BY comment_count DESC
LIMIT 50

WITH
    user_base AS (
        SELECT
            u.id AS user_id,
            u.reputation,
            u.creationdate
        FROM users u
    ),
    posts_owned AS (
        SELECT
            p.owneruserid AS user_id,
            COUNT(*) AS posts_owned,
            COALESCE(SUM(p.score), 0) AS total_post_score,
            COALESCE(SUM(p.viewcount), 0) AS total_viewcount,
            COALESCE(SUM(p.answercount), 0) AS total_answercount,
            COALESCE(SUM(p.commentcount), 0) AS total_commentcount,
            COALESCE(SUM(p.favoritecount), 0) AS total_favoritecount
        FROM posts p
        GROUP BY p.owneruserid
    ),
    comments_by_user AS (
        SELECT
            c.userid AS user_id,
            COUNT(*) AS comments_made,
            COALESCE(SUM(c.score), 0) AS total_comment_score
        FROM comments c
        GROUP BY c.userid
    ),
    votes_by_user AS (
        SELECT
            v.userid AS user_id,
            COUNT(*) AS votes_cast,
            SUM(CASE WHEN v.votetypeid = 2 THEN 1 ELSE 0 END) AS upvotes_cast,
            SUM(CASE WHEN v.votetypeid = 3 THEN 1 ELSE 0 END) AS downvotes_cast
        FROM votes v
        GROUP BY v.userid
    ),
    badges_by_user AS (
        SELECT
            b.userid AS user_id,
            COUNT(*) AS badges_earned
        FROM badges b
        GROUP BY b.userid
    ),
    posthistory_by_user AS (
        SELECT
            ph.userid AS user_id,
            COUNT(*) AS posthistory_actions
        FROM posthistory ph
        GROUP BY ph.userid
    ),
    comments_on_owned_posts AS (
        SELECT
            p.owneruserid AS user_id,
            COUNT(*) AS comments_received_on_posts
        FROM comments c
        JOIN posts p ON c.postid = p.id
        GROUP BY p.owneruserid
    ),
    votes_on_owned_posts AS (
        SELECT
            p.owneruserid AS user_id,
            COUNT(*) AS votes_received_on_posts
        FROM votes v
        JOIN posts p ON v.postid = p.id
        GROUP BY p.owneruserid
    ),
    tags_on_owned_posts AS (
        SELECT
            p.owneruserid AS user_id,
            COUNT(*) AS tags_on_posts
        FROM tags t
        JOIN posts p ON t.excerptpostid = p.id
        GROUP BY p.owneruserid
    ),
    postlinks_from_owned_posts AS (
        SELECT
            p.owneruserid AS user_id,
            COUNT(*) AS outgoing_links
        FROM postlinks pl
        JOIN posts p ON pl.postid = p.id
        GROUP BY p.owneruserid
    ),
    postlinks_to_owned_posts AS (
        SELECT
            p.owneruserid AS user_id,
            COUNT(*) AS incoming_links
        FROM postlinks pl
        JOIN posts p ON pl.relatedpostid = p.id
        GROUP BY p.owneruserid
    )
SELECT
    ub.user_id,
    ub.reputation,
    ub.creationdate,
    COALESCE(po.posts_owned, 0) AS posts_owned,
    COALESCE(po.total_post_score, 0) AS total_post_score,
    COALESCE(po.total_viewcount, 0) AS total_viewcount,
    COALESCE(po.total_answercount, 0) AS total_answercount,
    COALESCE(po.total_commentcount, 0) AS total_commentcount,
    COALESCE(po.total_favoritecount, 0) AS total_favoritecount,
    COALESCE(cbu.comments_made, 0) AS comments_made,
    COALESCE(cbu.total_comment_score, 0) AS total_comment_score,
    COALESCE(vbu.votes_cast, 0) AS votes_cast,
    COALESCE(vbu.upvotes_cast, 0) AS upvotes_cast,
    COALESCE(vbu.downvotes_cast, 0) AS downvotes_cast,
    COALESCE(bb.badges_earned, 0) AS badges_earned,
    COALESCE(phb.posthistory_actions, 0) AS posthistory_actions,
    COALESCE(cop.comments_received_on_posts, 0) AS comments_received_on_posts,
    COALESCE(vop.votes_received_on_posts, 0) AS votes_received_on_posts,
    COALESCE(tok.tags_on_posts, 0) AS tags_on_posts,
    COALESCE(olf.outgoing_links, 0) AS outgoing_links,
    COALESCE(ilf.incoming_links, 0) AS incoming_links
FROM user_base ub
LEFT JOIN posts_owned po ON po.user_id = ub.user_id
LEFT JOIN comments_by_user cbu ON cbu.user_id = ub.user_id
LEFT JOIN votes_by_user vbu ON vbu.user_id = ub.user_id
LEFT JOIN badges_by_user bb ON bb.user_id = ub.user_id
LEFT JOIN posthistory_by_user phb ON phb.user_id = ub.user_id
LEFT JOIN comments_on_owned_posts cop ON cop.user_id = ub.user_id
LEFT JOIN votes_on_owned_posts vop ON vop.user_id = ub.user_id
LEFT JOIN tags_on_owned_posts tok ON tok.user_id = ub.user_id
LEFT JOIN postlinks_from_owned_posts olf ON olf.user_id = ub.user_id
LEFT JOIN postlinks_to_owned_posts ilf ON ilf.user_id = ub.user_id
ORDER BY ub.reputation DESC
LIMIT 100

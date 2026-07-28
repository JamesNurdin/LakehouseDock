WITH promo_sales AS (
    SELECT
        p.p_promo_id,
        p.p_promo_name,
        p.p_purpose,
        p.p_channel_email,
        p.p_channel_details,
        regexp_extract(p.p_channel_details, '(\\w+) families', 1) AS extracted_family,
        CASE
            WHEN regexp_like(p.p_channel_details, 'Young families') THEN 'Young'
            ELSE 'Other'
        END AS family_category,
        SUM(ss.ss_net_paid) AS total_net_paid,
        SUM(ss.ss_quantity) AS total_qty,
        COUNT(DISTINCT ss.ss_ticket_number) AS ticket_cnt
    FROM promotion p
    JOIN store_sales ss
        ON ss.ss_promo_sk = p.p_promo_sk
    WHERE p.p_channel_email LIKE 'Y' -- email channel active
      AND p.p_channel_details LIKE '%families%'
      AND p.p_promo_name LIKE '%Holiday%'
    GROUP BY
        p.p_promo_id,
        p.p_promo_name,
        p.p_purpose,
        p.p_channel_email,
        p.p_channel_details,
        regexp_extract(p.p_channel_details, '(\\w+) families', 1),
        CASE
            WHEN regexp_like(p.p_channel_details, 'Young families') THEN 'Young'
            ELSE 'Other'
        END
)
SELECT
    p_promo_id,
    p_promo_name,
    p_purpose,
    family_category,
    extracted_family,
    total_net_paid,
    total_qty,
    ticket_cnt,
    CONCAT(p_promo_name, ' - ', COALESCE(p_purpose, '')) AS promo_desc
FROM promo_sales
ORDER BY total_net_paid DESC
LIMIT 20

WITH promo_returns AS (
    SELECT
        p.p_promo_id,
        p.p_promo_name,
        COUNT(DISTINCT sr.sr_ticket_number) AS num_returns,
        SUM(sr.sr_return_amt) AS total_return_amount,
        AVG(sr.sr_return_quantity) AS avg_return_qty,
        SUM(CASE WHEN wp.wp_type = 'Landing' THEN wp.wp_link_count ELSE 0 END) AS total_landing_links,
        AVG(wp.wp_char_count) FILTER (WHERE wp.wp_char_count IS NOT NULL) AS avg_page_char_count
    FROM promotion p
    JOIN store_returns sr
        ON p.p_item_sk = sr.sr_item_sk
    LEFT JOIN web_page wp
        ON sr.sr_customer_sk = wp.wp_customer_sk
    WHERE p.p_discount_active = 'Y'
      AND p.p_cost >= 500.00
      AND sr.sr_returned_date_sk BETWEEN 2450150 AND 2450712
    GROUP BY p.p_promo_id, p.p_promo_name
    HAVING SUM(sr.sr_return_amt) > 1000
)
SELECT
    pr.*, 
    RANK() OVER (ORDER BY pr.total_return_amount DESC) AS return_amount_rank
FROM promo_returns pr
ORDER BY pr.total_return_amount DESC
LIMIT 50

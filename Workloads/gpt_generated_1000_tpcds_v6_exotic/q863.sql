WITH filtered_promotions AS (
    SELECT p_promo_sk, p_promo_id, p_cost, p_start_date_sk, p_channel_radio, p_purpose, p_discount_active
    FROM promotion
    WHERE p_start_date_sk >= 2450150
      AND p_channel_radio = 'N'
      AND p_purpose = 'Unknown'
)
SELECT
    c.c_customer_id,
    p.p_promo_id,
    SUM(ss.ss_net_paid) AS total_net_paid,
    SUM(cr.cr_return_amount) AS total_catalog_return,
    SUM(wr.wr_return_amt) AS total_web_return,
    COUNT(DISTINCT ss.ss_ticket_number) AS sales_txn_count,
    AVG(p.p_cost) AS avg_promo_cost
FROM customer c
JOIN store_sales ss
    ON ss.ss_customer_sk = c.c_customer_sk
JOIN filtered_promotions p
    ON ss.ss_promo_sk = p.p_promo_sk
LEFT JOIN catalog_returns cr
    ON cr.cr_refunded_customer_sk = c.c_customer_sk
LEFT JOIN web_returns wr
    ON wr.wr_refunded_customer_sk = c.c_customer_sk
LEFT JOIN web_page wp
    ON wp.wp_web_page_sk = wr.wr_web_page_sk
WHERE c.c_first_sales_date_sk BETWEEN 2450000 AND 2452000
  AND ss.ss_sold_date_sk = 2450000
  AND cr.cr_returned_date_sk = 2450000
  AND wr.wr_returned_date_sk = 2450000
  AND wp.wp_max_ad_count >= 2
  AND wp.wp_image_count <= 5
  AND EXISTS (
        SELECT 1
        FROM promotion p2
        WHERE p2.p_promo_sk = ss.ss_promo_sk
          AND p2.p_discount_active = 'Y'
      )
GROUP BY GROUPING SETS (
    (c.c_customer_id, p.p_promo_id),
    (c.c_customer_id),
    ()
)
ORDER BY total_net_paid DESC
LIMIT 100

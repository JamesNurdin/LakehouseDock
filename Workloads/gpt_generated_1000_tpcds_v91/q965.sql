/*
 Goal: Analyze store performance and return losses by state and promotion, aggregating profit, return loss and coupon usage, while excluding orders that also appear in web returns and focusing on active promotions.
*/
WITH catalog_ret AS (
    SELECT *
    FROM catalog_returns
),
web_ret AS (
    SELECT *
    FROM web_returns
)
SELECT
    s.s_state,
    p.p_promo_name,
    COUNT(DISTINCT ss.ss_ticket_number) AS store_sales_orders,
    SUM(ss.ss_net_profit)               AS total_store_profit,
    SUM(cr.cr_net_loss)                  AS total_catalog_return_loss,
    SUM(wr.wr_net_loss)                  AS total_web_return_loss,
    AVG(ss.ss_coupon_amt)                AS avg_coupon_amount,
    COUNT(DISTINCT CASE WHEN r_cr.r_reason_desc = 'Damaged' THEN cr.cr_order_number END) AS damaged_catalog_returns,
    COUNT(DISTINCT CASE WHEN r_wr.r_reason_desc = 'Customer Not Satisfied' THEN wr.wr_order_number END) AS cs_web_returns
FROM store_sales ss
    JOIN customer c_sales ON ss.ss_customer_sk = c_sales.c_customer_sk
    JOIN customer_address ca_sales ON ss.ss_addr_sk = ca_sales.ca_address_sk
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
    /* Catalog returns and related dimensions */
    JOIN catalog_ret cr ON cr.cr_refunded_customer_sk = c_sales.c_customer_sk
        AND cr.cr_refunded_addr_sk = ca_sales.ca_address_sk
    JOIN ship_mode sm ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN reason r_cr ON cr.cr_reason_sk = r_cr.r_reason_sk
    JOIN customer c_refunded ON cr.cr_refunded_customer_sk = c_refunded.c_customer_sk
    JOIN customer c_returning ON cr.cr_returning_customer_sk = c_returning.c_customer_sk
    JOIN customer_address ca_refunded ON cr.cr_refunded_addr_sk = ca_refunded.ca_address_sk
    JOIN customer_address ca_returning ON cr.cr_returning_addr_sk = ca_returning.ca_address_sk
    /* Web returns and related dimensions */
    JOIN web_ret wr ON wr.wr_refunded_customer_sk = c_sales.c_customer_sk
        AND wr.wr_refunded_addr_sk = ca_sales.ca_address_sk
    JOIN web_page wp ON wr.wr_web_page_sk = wp.wp_web_page_sk
    JOIN reason r_wr ON wr.wr_reason_sk = r_wr.r_reason_sk
    JOIN customer c_web_refunded ON wr.wr_refunded_customer_sk = c_web_refunded.c_customer_sk
    JOIN customer c_web_returning ON wr.wr_returning_customer_sk = c_web_returning.c_customer_sk
    JOIN customer_address ca_web_refunded ON wr.wr_refunded_addr_sk = ca_web_refunded.ca_address_sk
    JOIN customer_address ca_web_returning ON wr.wr_returning_addr_sk = ca_web_returning.ca_address_sk
    /* Additional joins using the remaining rules */
    JOIN customer c_page ON wp.wp_customer_sk = c_page.c_customer_sk
    JOIN customer_address ca_current ON c_sales.c_current_addr_sk = ca_current.ca_address_sk
WHERE cr.cr_order_number IN (
    SELECT cr2.cr_order_number
    FROM catalog_returns cr2
    EXCEPT
    SELECT wr2.wr_order_number
    FROM web_returns wr2
)
  AND EXISTS (
    SELECT 1
    FROM promotion p2
    WHERE p2.p_promo_id = p.p_promo_id
      AND p2.p_discount_active = 'Y'
)
GROUP BY s.s_state, p.p_promo_name
ORDER BY total_store_profit DESC
LIMIT 100

-- Goal: Compare net profit of store sales against catalog returns by store, department, and hour of day, filtering to PM sales in California stores and ranking the results.
WITH avg_item_price AS (
    SELECT avg(i2.i_current_price) AS avg_price
    FROM item i2
)
SELECT
    s.s_store_name,
    cp.cp_department,
    t_sales.t_hour,
    SUM(ss.ss_net_paid)                         AS total_sales,
    SUM(cr.cr_return_amount)                    AS total_returns,
    SUM(ss.ss_net_profit) - SUM(cr.cr_net_loss) AS net_profit,
    COUNT(cr.cr_return_quantity)                AS return_count,
    ap.avg_price                                 AS overall_avg_item_price
FROM store_sales ss
JOIN time_dim t_sales ON ss.ss_sold_time_sk = t_sales.t_time_sk
JOIN item i ON ss.ss_item_sk = i.i_item_sk
JOIN customer c_ss ON ss.ss_customer_sk = c_ss.c_customer_sk
JOIN customer_demographics cd_ss ON ss.ss_cdemo_sk = cd_ss.cd_demo_sk
JOIN household_demographics hd_ss ON ss.ss_hdemo_sk = hd_ss.hd_demo_sk
JOIN customer_address ca_ss ON ss.ss_addr_sk = ca_ss.ca_address_sk
JOIN store s ON ss.ss_store_sk = s.s_store_sk
JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
-- Catalog returns and related dimensions
JOIN catalog_returns cr ON cr.cr_item_sk = i.i_item_sk
JOIN time_dim t_ret ON cr.cr_returned_time_sk = t_ret.t_time_sk
JOIN catalog_page cp ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
JOIN ship_mode sm ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
JOIN warehouse wh ON cr.cr_warehouse_sk = wh.w_warehouse_sk
JOIN customer c_refund ON cr.cr_refunded_customer_sk = c_refund.c_customer_sk
JOIN customer_demographics cd_refund ON cr.cr_refunded_cdemo_sk = cd_refund.cd_demo_sk
JOIN household_demographics hd_refund ON cr.cr_refunded_hdemo_sk = hd_refund.hd_demo_sk
JOIN customer_address ca_refund ON cr.cr_refunded_addr_sk = ca_refund.ca_address_sk
JOIN customer c_return ON cr.cr_returning_customer_sk = c_return.c_customer_sk
JOIN customer_demographics cd_return ON cr.cr_returning_cdemo_sk = cd_return.cd_demo_sk
JOIN household_demographics hd_return ON cr.cr_returning_hdemo_sk = hd_return.hd_demo_sk
JOIN customer_address ca_return ON cr.cr_returning_addr_sk = ca_return.ca_address_sk
-- Web page activity for the same customer who made the sale
JOIN web_page wp ON wp.wp_customer_sk = c_ss.c_customer_sk
CROSS JOIN avg_item_price ap
WHERE t_sales.t_am_pm = 'PM'
  AND s.s_state = 'CA'
GROUP BY s.s_store_name, cp.cp_department, t_sales.t_hour, ap.avg_price
HAVING SUM(ss.ss_net_paid) > 10000
ORDER BY net_profit DESC

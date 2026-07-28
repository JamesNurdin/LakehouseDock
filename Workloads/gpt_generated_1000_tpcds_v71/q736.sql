WITH top_items AS (
    SELECT ss_item_sk
    FROM store_sales
    GROUP BY ss_item_sk
    ORDER BY SUM(ss_ext_sales_price) DESC
    LIMIT 5
)
SELECT
    i.i_category,
    r.r_reason_desc,
    SUM(cr.cr_net_loss) AS total_catalog_net_loss,
    SUM(wr.wr_net_loss) AS total_web_net_loss,
    SUM(ss.ss_ext_sales_price) AS total_sales,
    COUNT(DISTINCT ss.ss_ticket_number) AS distinct_sales_transactions,
    AVG(ss.ss_sales_price) AS avg_sales_price,
    (
        SELECT MAX(ss2.ss_ext_sales_price)
        FROM store_sales ss2
        WHERE ss2.ss_item_sk = i.i_item_sk
    ) AS max_item_sales_price,
    CASE WHEN EXISTS (
        SELECT 1
        FROM promotion p2
        WHERE p2.p_item_sk = i.i_item_sk
          AND p2.p_discount_active = 'Y'
    ) THEN 1 ELSE 0 END AS has_active_promo
FROM item i
JOIN catalog_returns cr ON cr.cr_item_sk = i.i_item_sk
JOIN web_returns wr ON wr.wr_item_sk = i.i_item_sk
JOIN store_sales ss ON ss.ss_item_sk = i.i_item_sk
JOIN time_dim t_ss ON t_ss.t_time_sk = ss.ss_sold_time_sk
JOIN time_dim t_cr ON t_cr.t_time_sk = cr.cr_returned_time_sk
JOIN time_dim t_wr ON t_wr.t_time_sk = wr.wr_returned_time_sk
JOIN ship_mode sm ON sm.sm_ship_mode_sk = cr.cr_ship_mode_sk
JOIN warehouse w ON w.w_warehouse_sk = cr.cr_warehouse_sk
JOIN reason r ON r.r_reason_sk = cr.cr_reason_sk
JOIN promotion p ON p.p_promo_sk = ss.ss_promo_sk
JOIN customer c ON c.c_customer_sk = cr.cr_refunded_customer_sk
JOIN customer_address ca ON ca.ca_address_sk = cr.cr_refunded_addr_sk
JOIN customer_demographics cd ON cd.cd_demo_sk = cr.cr_refunded_cdemo_sk
JOIN household_demographics hd ON hd.hd_demo_sk = cr.cr_refunded_hdemo_sk
WHERE i.i_class_id = 12
  AND i.i_size = 'large'
  AND t_ss.t_hour BETWEEN 9 AND 12
  AND p.p_promo_name = 'Summer Sale'
  AND sm.sm_type = 'AIR'
  AND w.w_state = 'CA'
  AND c.c_birth_year = 1980
  AND i.i_item_sk IN (SELECT ss_item_sk FROM top_items)
GROUP BY i.i_category, r.r_reason_desc, i.i_item_sk
ORDER BY total_catalog_net_loss DESC, i.i_category
LIMIT 100

WITH recent_sales AS (
    SELECT
        i.i_item_sk,
        SUM(ss.ss_ext_sales_price) AS store_sales,
        SUM(ws.ws_ext_sales_price) AS web_sales
    FROM item i
    JOIN store_sales ss ON ss.ss_item_sk = i.i_item_sk
    JOIN web_sales ws ON ws.ws_item_sk = i.i_item_sk
    WHERE i.i_size = 'large'
      AND i.i_rec_start_date >= DATE '2000-01-01'
    GROUP BY i.i_item_sk
)
SELECT
    i.i_item_sk,
    i.i_category,
    i.i_brand,
    rs.store_sales,
    rs.web_sales,
    COALESCE(SUM(cr.cr_return_amount), 0) AS catalog_return_amount,
    COALESCE(SUM(wr.wr_return_amt), 0) AS web_return_amount,
    (rs.store_sales + rs.web_sales - COALESCE(SUM(cr.cr_return_amount), 0) - COALESCE(SUM(wr.wr_return_amt), 0)) AS net_revenue,
    s.s_state,
    w_ws.w_state,
    ws_site.web_name,
    td_ss.t_meal_time,
    CASE WHEN EXISTS (
        SELECT 1 FROM promotion p_sub
        WHERE p_sub.p_item_sk = i.i_item_sk
          AND p_sub.p_discount_active = 'Y'
    ) THEN 1 ELSE 0 END AS has_active_promo
FROM recent_sales rs
JOIN item i ON i.i_item_sk = rs.i_item_sk
LEFT JOIN store_sales ss ON ss.ss_item_sk = rs.i_item_sk
LEFT JOIN store s ON s.s_store_sk = ss.ss_store_sk
LEFT JOIN time_dim td_ss ON td_ss.t_time_sk = ss.ss_sold_time_sk
LEFT JOIN promotion p_ss ON p_ss.p_promo_sk = ss.ss_promo_sk
LEFT JOIN customer c_ss ON c_ss.c_customer_sk = ss.ss_customer_sk
LEFT JOIN customer_demographics cd_ss ON cd_ss.cd_demo_sk = ss.ss_cdemo_sk
LEFT JOIN web_sales ws ON ws.ws_item_sk = rs.i_item_sk
LEFT JOIN web_site ws_site ON ws_site.web_site_sk = ws.ws_web_site_sk
LEFT JOIN warehouse w_ws ON w_ws.w_warehouse_sk = ws.ws_warehouse_sk
LEFT JOIN promotion p_ws ON p_ws.p_promo_sk = ws.ws_promo_sk
LEFT JOIN time_dim td_ws ON td_ws.t_time_sk = ws.ws_sold_time_sk
LEFT JOIN catalog_returns cr ON cr.cr_item_sk = rs.i_item_sk
LEFT JOIN catalog_page cp ON cp.cp_catalog_page_sk = cr.cr_catalog_page_sk
LEFT JOIN warehouse w_cr ON w_cr.w_warehouse_sk = cr.cr_warehouse_sk
LEFT JOIN time_dim td_cr ON td_cr.t_time_sk = cr.cr_returned_time_sk
LEFT JOIN web_returns wr ON wr.wr_item_sk = rs.i_item_sk AND wr.wr_order_number = ws.ws_order_number
LEFT JOIN time_dim td_wr ON td_wr.t_time_sk = wr.wr_returned_time_sk
LEFT JOIN customer c_wr_refund ON c_wr_refund.c_customer_sk = wr.wr_refunded_customer_sk
LEFT JOIN customer_demographics cd_wr_refund ON cd_wr_refund.cd_demo_sk = wr.wr_refunded_cdemo_sk
WHERE i.i_size = 'large'
  AND i.i_rec_start_date >= DATE '2000-01-01'
  AND i.i_category = 'Sports'
  AND s.s_state = 'CA'
  AND w_ws.w_state = 'CA'
  AND ws_site.web_name = 'Online Store'
  AND td_ss.t_meal_time = 'dinner'
  AND p_ss.p_discount_active = 'Y'
GROUP BY
    i.i_item_sk,
    i.i_category,
    i.i_brand,
    rs.store_sales,
    rs.web_sales,
    s.s_state,
    w_ws.w_state,
    ws_site.web_name,
    td_ss.t_meal_time
ORDER BY net_revenue DESC
LIMIT 100

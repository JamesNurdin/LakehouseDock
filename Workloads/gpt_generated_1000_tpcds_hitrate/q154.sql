WITH customer_sales AS (
    SELECT
        c.c_customer_sk,
        SUM(cs.cs_net_paid) AS total_catalog_sales,
        SUM(ws.ws_net_paid) AS total_web_sales,
        COUNT(DISTINCT cs.cs_order_number) AS catalog_orders,
        COUNT(DISTINCT ws.ws_order_number) AS web_orders
    FROM catalog_sales cs
    JOIN customer c ON cs.cs_bill_customer_sk = c.c_customer_sk
    JOIN web_sales ws ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN date_dim d_cs ON cs.cs_sold_date_sk = d_cs.d_date_sk
    JOIN date_dim d_ws ON ws.ws_sold_date_sk = d_ws.d_date_sk
    WHERE d_cs.d_year = 2002
      AND d_ws.d_year = 2002
    GROUP BY c.c_customer_sk
)
SELECT
    c.c_customer_id,
    cc.cc_name,
    s.s_store_name,
    w.w_warehouse_name,
    p.p_promo_name,
    r_cr.r_reason_desc,
    SUM(cr.cr_return_amount) AS total_catalog_return_amount,
    SUM(wr.wr_return_amt) AS total_web_return_amount,
    COUNT(DISTINCT cs.cs_order_number) AS catalog_order_cnt,
    COUNT(DISTINCT ws.ws_order_number) AS web_order_cnt,
    AVG(p.p_cost) AS avg_promo_cost
FROM catalog_sales cs
JOIN date_dim d_cs_sold ON cs.cs_sold_date_sk = d_cs_sold.d_date_sk
JOIN time_dim t_cs ON cs.cs_sold_time_sk = t_cs.t_time_sk
JOIN customer c ON cs.cs_bill_customer_sk = c.c_customer_sk
JOIN household_demographics hd ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
JOIN catalog_returns cr ON cr.cr_order_number = cs.cs_order_number
    AND cr.cr_item_sk = cs.cs_item_sk
JOIN reason r_cr ON cr.cr_reason_sk = r_cr.r_reason_sk
JOIN date_dim d_cr_return ON cr.cr_returned_date_sk = d_cr_return.d_date_sk
JOIN time_dim t_cr ON cr.cr_returned_time_sk = t_cr.t_time_sk
JOIN store s ON s.s_closed_date_sk = d_cr_return.d_date_sk
JOIN web_sales ws ON ws.ws_bill_customer_sk = c.c_customer_sk
JOIN date_dim d_ws_sold ON ws.ws_sold_date_sk = d_ws_sold.d_date_sk
JOIN time_dim t_ws ON ws.ws_sold_time_sk = t_ws.t_time_sk
JOIN web_returns wr ON wr.wr_order_number = ws.ws_order_number
    AND wr.wr_item_sk = ws.ws_item_sk
JOIN reason r_wr ON wr.wr_reason_sk = r_wr.r_reason_sk
JOIN date_dim d_wr_return ON wr.wr_returned_date_sk = d_wr_return.d_date_sk
JOIN time_dim t_wr ON wr.wr_returned_time_sk = t_wr.t_time_sk
JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
JOIN web_site wsite ON ws.ws_web_site_sk = wsite.web_site_sk
JOIN date_dim d_wsite_open ON wsite.web_open_date_sk = d_wsite_open.d_date_sk
JOIN date_dim d_wsite_close ON wsite.web_close_date_sk = d_wsite_close.d_date_sk
JOIN date_dim d_wp_creation ON wp.wp_creation_date_sk = d_wp_creation.d_date_sk
JOIN date_dim d_wp_access ON wp.wp_access_date_sk = d_wp_access.d_date_sk
JOIN date_dim d_cc_open ON cc.cc_open_date_sk = d_cc_open.d_date_sk
JOIN date_dim d_cc_closed ON cc.cc_closed_date_sk = d_cc_closed.d_date_sk
JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
WHERE d_cs_sold.d_year = 2002
  AND t_cs.t_hour BETWEEN 9 AND 17
  AND w.w_state = 'CA'
  AND cc.cc_market_manager = 'John Doe'
  AND p.p_channel_details LIKE '%teachers%'
  AND r_cr.r_reason_desc LIKE '%damaged%'
  AND d_cr_return.d_date BETWEEN DATE '2002-01-01' AND DATE '2002-12-31'
  AND EXISTS (
        SELECT 1
        FROM customer_sales cs2
        WHERE cs2.c_customer_sk = c.c_customer_sk
          AND cs2.total_catalog_sales > 1000
    )
GROUP BY
    c.c_customer_id,
    cc.cc_name,
    s.s_store_name,
    w.w_warehouse_name,
    p.p_promo_name,
    r_cr.r_reason_desc
ORDER BY total_catalog_return_amount DESC
LIMIT 100

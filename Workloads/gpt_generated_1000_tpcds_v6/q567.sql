WITH per_store AS (
    SELECT
        s.s_store_id,
        SUM(ws.ws_net_paid) AS total_net_paid,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        SUM(cr.cr_return_amount) AS total_return_amount,
        SUM(wr.wr_return_amt) AS total_web_return_amount,
        COUNT(*) AS sales_cnt
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN household_demographics hd ON ws.ws_bill_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
    JOIN web_site wsite ON ws.ws_web_site_sk = wsite.web_site_sk
    JOIN ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
    JOIN catalog_returns cr ON cr.cr_returned_date_sk = d.d_date_sk
    JOIN call_center cc ON cr.cr_call_center_sk = cc.cc_call_center_sk
    JOIN catalog_page cp ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN web_returns wr ON wr.wr_order_number = ws.ws_order_number AND wr.wr_item_sk = ws.ws_item_sk
    JOIN inventory inv ON inv.inv_date_sk = d.d_date_sk
    JOIN store s ON s.s_closed_date_sk = d.d_date_sk
    WHERE d.d_year = 2001
      AND sm.sm_carrier = 'AIRBORNE'
      AND cc.cc_division = 3
      AND ws.ws_list_price > 100
      AND ib.ib_lower_bound >= 20000
    GROUP BY s.s_store_id
)
SELECT
    ps.s_store_id,
    ps.total_net_paid,
    ps.total_sales,
    ps.total_return_amount,
    ps.total_web_return_amount,
    (ps.total_net_paid - ps.total_return_amount - ps.total_web_return_amount) AS net_revenue,
    (SELECT AVG(total_net_paid - total_return_amount - total_web_return_amount) FROM per_store) AS avg_net_revenue_across_stores
FROM per_store ps
WHERE (ps.total_net_paid - ps.total_return_amount - ps.total_web_return_amount) > 
      (SELECT AVG(total_net_paid - total_return_amount - total_web_return_amount) FROM per_store)
ORDER BY net_revenue DESC
LIMIT 100

WITH base AS (
    SELECT
        d_sales.d_year AS sales_year,
        i.i_category,
        p.p_promo_name,
        SUM(ws.ws_net_paid) AS total_net_paid,
        SUM(ws.ws_net_profit) AS total_net_profit,
        SUM(cr.cr_return_amount) AS total_catalog_return_amount,
        SUM(wr.wr_return_amt) AS total_web_return_amount,
        COUNT(DISTINCT i.i_item_sk) AS distinct_items_sold
    FROM catalog_returns cr
    JOIN date_dim d_cr ON cr.cr_returned_date_sk = d_cr.d_date_sk
    JOIN item i ON cr.cr_item_sk = i.i_item_sk
    JOIN catalog_page cp ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN ship_mode sm ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN warehouse w ON cr.cr_warehouse_sk = w.w_warehouse_sk
    JOIN household_demographics hd_refund ON cr.cr_refunded_hdemo_sk = hd_refund.hd_demo_sk
    JOIN income_band ib ON hd_refund.hd_income_band_sk = ib.ib_income_band_sk
    JOIN customer_address ca ON cr.cr_refunded_addr_sk = ca.ca_address_sk
    JOIN web_sales ws ON cr.cr_order_number = ws.ws_order_number
    JOIN date_dim d_sales ON ws.ws_sold_date_sk = d_sales.d_date_sk
    JOIN time_dim t_sales ON ws.ws_sold_time_sk = t_sales.t_time_sk
    JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
    JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
    JOIN web_site site ON ws.ws_web_site_sk = site.web_site_sk
    JOIN ship_mode sm_ws ON ws.ws_ship_mode_sk = sm_ws.sm_ship_mode_sk
    JOIN warehouse w_ws ON ws.ws_warehouse_sk = w_ws.w_warehouse_sk
    JOIN store s ON s.s_closed_date_sk = d_sales.d_date_sk
    JOIN web_returns wr ON ws.ws_order_number = wr.wr_order_number
    JOIN date_dim d_wr ON wr.wr_returned_date_sk = d_wr.d_date_sk
    JOIN time_dim t_wr ON wr.wr_returned_time_sk = t_wr.t_time_sk
    WHERE d_sales.d_year = 2001
      AND i.i_brand_id = 10008011
      AND w.w_state = 'CA'
      AND site.web_country = 'United States'
      AND p.p_discount_active = 'Y'
    GROUP BY ROLLUP (d_sales.d_year, i.i_category, p.p_promo_name)
)
SELECT
    sales_year,
    i_category,
    p_promo_name,
    total_net_paid,
    total_net_profit,
    total_catalog_return_amount,
    total_web_return_amount,
    distinct_items_sold,
    ROW_NUMBER() OVER (PARTITION BY sales_year ORDER BY total_net_paid DESC) AS sales_rank_year
FROM base
ORDER BY sales_year, i_category, p_promo_name
LIMIT 100

WITH sales_agg AS (
    SELECT
        hd.hd_income_band_sk AS hd_income_band_sk,
        ib.ib_lower_bound AS ib_lower_bound,
        ib.ib_upper_bound AS ib_upper_bound,
        SUM(ws.ws_net_profit) AS total_profit,
        COUNT(DISTINCT c.c_customer_sk) AS num_customers
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN customer_address ca ON ws.ws_bill_addr_sk = ca.ca_address_sk
    JOIN household_demographics hd ON ws.ws_bill_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
    JOIN ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
    JOIN inventory inv ON inv.inv_item_sk = i.i_item_sk
    JOIN date_dim di ON inv.inv_date_sk = di.d_date_sk
    JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
    JOIN web_site wsit ON ws.ws_web_site_sk = wsit.web_site_sk
    JOIN web_returns wr ON wr.wr_order_number = ws.ws_order_number
    JOIN store_returns sr ON sr.sr_customer_sk = c.c_customer_sk
    JOIN store s ON sr.sr_store_sk = s.s_store_sk
    WHERE d.d_year = 2001
      AND i.i_color = 'pink'
      AND ib.ib_lower_bound > 30000
    GROUP BY hd.hd_income_band_sk, ib.ib_lower_bound, ib.ib_upper_bound
)
SELECT
    hd_income_band_sk,
    ib_lower_bound,
    ib_upper_bound,
    total_profit,
    num_customers,
    total_profit / NULLIF(num_customers, 0) AS avg_profit_per_customer
FROM sales_agg
ORDER BY avg_profit_per_customer DESC
LIMIT 100

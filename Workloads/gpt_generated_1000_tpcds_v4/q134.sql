WITH cs_agg AS (
    SELECT
        cs.cs_call_center_sk,
        d.d_year,
        SUM(cs.cs_net_profit) AS total_cs_net_profit,
        SUM(cs.cs_ext_sales_price) AS total_cs_sales
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    GROUP BY cs.cs_call_center_sk, d.d_year
)
SELECT
    s.s_store_name,
    s.s_state,
    cc.cc_name,
    ws_year.d_year,
    SUM(ss.ss_net_profit) AS store_net_profit,
    COALESCE(cs_agg.total_cs_net_profit, 0) AS catalog_net_profit,
    CASE WHEN SUM(ss.ss_net_profit) > 100000 THEN 'High' ELSE 'Low' END AS profit_category,
    (
        SELECT AVG(wr2.wr_net_loss)
        FROM web_returns wr2
        JOIN date_dim d2 ON wr2.wr_returned_date_sk = d2.d_date_sk
        WHERE d2.d_year = ws_year.d_year
    ) AS avg_return_loss_year
FROM store_sales ss
JOIN store s
    ON ss.ss_store_sk = s.s_store_sk
JOIN date_dim ws_year
    ON ss.ss_sold_date_sk = ws_year.d_date_sk
JOIN time_dim td
    ON ss.ss_sold_time_sk = td.t_time_sk
JOIN customer c
    ON ss.ss_customer_sk = c.c_customer_sk
JOIN household_demographics hd
    ON ss.ss_hdemo_sk = hd.hd_demo_sk
JOIN income_band ib
    ON hd.hd_income_band_sk = ib.ib_income_band_sk
JOIN call_center cc
    ON cc.cc_open_date_sk = ws_year.d_date_sk
LEFT JOIN cs_agg
    ON cs_agg.cs_call_center_sk = cc.cc_call_center_sk
   AND cs_agg.d_year = ws_year.d_year
JOIN web_sales ws
    ON ws.ws_sold_date_sk = ws_year.d_date_sk
   AND ws.ws_sold_time_sk = td.t_time_sk
   AND ws.ws_bill_customer_sk = c.c_customer_sk
   AND ws.ws_bill_hdemo_sk = hd.hd_demo_sk
JOIN ship_mode sm
    ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
JOIN web_page wp
    ON ws.ws_web_page_sk = wp.wp_web_page_sk
JOIN web_site web
    ON ws.ws_web_site_sk = web.web_site_sk
JOIN web_returns wr
    ON wr.wr_returned_date_sk = ws_year.d_date_sk
   AND wr.wr_returned_time_sk = td.t_time_sk
   AND wr.wr_item_sk = ws.ws_item_sk
   AND wr.wr_order_number = ws.ws_order_number
   AND wr.wr_web_page_sk = wp.wp_web_page_sk
WHERE ws_year.d_year BETWEEN 2000 AND 2002
  AND s.s_state = 'CA'
  AND web.web_country = 'United States'
  AND ib.ib_upper_bound > 50000
GROUP BY
    s.s_store_name,
    s.s_state,
    cc.cc_name,
    ws_year.d_year,
    cs_agg.total_cs_net_profit
ORDER BY store_net_profit DESC
LIMIT 100

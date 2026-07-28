WITH ws_avg AS (
    SELECT
        d2.d_year,
        AVG(ws2.ws_net_profit) AS avg_ws_profit_year
    FROM web_sales ws2
    JOIN date_dim d2 ON ws2.ws_sold_date_sk = d2.d_date_sk
    GROUP BY d2.d_year
)
SELECT
    d.d_year,
    s.s_store_id,
    SUM(cs.cs_net_profit) AS total_cs_profit,
    wa.avg_ws_profit_year,
    CASE WHEN SUM(cs.cs_net_profit) > 100000 THEN 'High' ELSE 'Medium' END AS profit_level,
    RANK() OVER (PARTITION BY d.d_year ORDER BY SUM(cs.cs_net_profit) DESC) AS profit_rank
FROM catalog_sales cs
JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
JOIN item i ON cs.cs_item_sk = i.i_item_sk
JOIN customer_address ca ON cs.cs_bill_addr_sk = ca.ca_address_sk
JOIN customer_demographics cd ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
JOIN household_demographics hd ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
JOIN store_returns sr ON i.i_item_sk = sr.sr_item_sk
JOIN store s ON sr.sr_store_sk = s.s_store_sk
JOIN web_sales ws ON i.i_item_sk = ws.ws_item_sk
JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
JOIN web_site wsite ON ws.ws_web_site_sk = wsite.web_site_sk
JOIN web_returns wr ON ws.ws_order_number = wr.wr_order_number
JOIN ws_avg wa ON wa.d_year = d.d_year
WHERE d.d_year = 2001
  AND i.i_category = 'Electronics'
  AND cc.cc_manager = 'Jack Little'
  AND ib.ib_lower_bound >= 50000
  AND ca.ca_state = 'CA'
GROUP BY d.d_year, s.s_store_id, wa.avg_ws_profit_year
HAVING SUM(cs.cs_net_profit) > 50000
ORDER BY total_cs_profit DESC
LIMIT 100

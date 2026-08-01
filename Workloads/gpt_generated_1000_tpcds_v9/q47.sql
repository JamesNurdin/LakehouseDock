WITH overall_profit AS (
    SELECT AVG(cs2.cs_net_profit) AS avg_profit
    FROM catalog_sales cs2
    JOIN date_dim d2 ON cs2.cs_sold_date_sk = d2.d_date_sk
    WHERE d2.d_year = 2001
)
SELECT
    cc.cc_name,
    s.s_store_name,
    ib.ib_lower_bound,
    ib.ib_upper_bound,
    d.d_month_seq,
    SUM(cs.cs_ext_sales_price) AS total_sales,
    SUM(cs.cs_net_profit) AS total_profit,
    AVG(ss.ss_sales_price) AS avg_store_sales_price,
    SUM(COALESCE(sr.sr_return_amt, 0)) AS total_store_return_amount,
    COUNT(DISTINCT cs.cs_order_number) AS distinct_order_cnt,
    MIN(cs.cs_sales_price) AS min_sales_price,
    MAX(cs.cs_sales_price) AS max_sales_price,
    (SELECT avg_profit FROM overall_profit) AS avg_profit_all_call_centers
FROM catalog_sales cs
JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
JOIN household_demographics hd ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
JOIN store_sales ss ON ss.ss_sold_date_sk = d.d_date_sk
JOIN store s ON ss.ss_store_sk = s.s_store_sk
LEFT JOIN store_returns sr ON sr.sr_ticket_number = ss.ss_ticket_number AND sr.sr_item_sk = ss.ss_item_sk
JOIN web_site ws ON ws.web_open_date_sk = d.d_date_sk
WHERE d.d_year = 2001
  AND w.w_gmt_offset = -5.00
  AND hd.hd_vehicle_count >= 2
  AND d.d_current_month = 'Y'
GROUP BY
    cc.cc_name,
    s.s_store_name,
    ib.ib_lower_bound,
    ib.ib_upper_bound,
    d.d_month_seq
ORDER BY total_sales DESC

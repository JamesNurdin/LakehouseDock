WITH cs_agg AS (
    SELECT
        cp.cp_department AS department,
        ib.ib_income_band_sk AS income_band_sk,
        SUM(cs.cs_net_profit) AS total_profit,
        COUNT(*) AS sales_cnt
    FROM catalog_sales cs
    JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN customer c ON cs.cs_bill_customer_sk = c.c_customer_sk
    JOIN customer_demographics cd ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    JOIN customer_address ca ON cs.cs_bill_addr_sk = ca.ca_address_sk
    JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
    JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
    JOIN time_dim t ON cs.cs_sold_time_sk = t.t_time_sk
    WHERE ca.ca_country = 'United States'
      AND ib.ib_upper_bound >= 50000
      AND t.t_hour BETWEEN 8 AND 20
      AND EXISTS (
            SELECT 1
            FROM store_returns sr
            JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
            WHERE sr.sr_customer_sk = c.c_customer_sk
              AND r.r_reason_desc = 'Damaged'
        )
    GROUP BY cp.cp_department, ib.ib_income_band_sk
),
ws_agg AS (
    SELECT
        'Web' AS department,
        ib2.ib_income_band_sk AS income_band_sk,
        SUM(ws.ws_net_profit) AS total_profit,
        COUNT(*) AS sales_cnt
    FROM web_sales ws
    JOIN customer c2 ON ws.ws_bill_customer_sk = c2.c_customer_sk
    JOIN customer_demographics cd2 ON ws.ws_bill_cdemo_sk = cd2.cd_demo_sk
    JOIN household_demographics hd2 ON ws.ws_bill_hdemo_sk = hd2.hd_demo_sk
    JOIN income_band ib2 ON hd2.hd_income_band_sk = ib2.ib_income_band_sk
    JOIN customer_address ca2 ON ws.ws_bill_addr_sk = ca2.ca_address_sk
    JOIN ship_mode sm2 ON ws.ws_ship_mode_sk = sm2.sm_ship_mode_sk
    JOIN warehouse w2 ON ws.ws_warehouse_sk = w2.w_warehouse_sk
    JOIN promotion p2 ON ws.ws_promo_sk = p2.p_promo_sk
    JOIN time_dim t2 ON ws.ws_sold_time_sk = t2.t_time_sk
    WHERE ca2.ca_country = 'United States'
      AND ib2.ib_upper_bound >= 50000
      AND t2.t_hour BETWEEN 8 AND 20
      AND EXISTS (
            SELECT 1
            FROM web_returns wr
            WHERE wr.wr_item_sk = ws.ws_item_sk
              AND wr.wr_order_number = ws.ws_order_number
              AND wr.wr_return_amt > 500
        )
    GROUP BY ib2.ib_income_band_sk
)
SELECT
    department,
    income_band_sk,
    AVG(total_profit) AS avg_profit,
    SUM(sales_cnt) AS total_sales
FROM (
    SELECT * FROM cs_agg
    UNION ALL
    SELECT * FROM ws_agg
) u
GROUP BY department, income_band_sk
HAVING AVG(total_profit) > 1000
ORDER BY avg_profit DESC
LIMIT 100

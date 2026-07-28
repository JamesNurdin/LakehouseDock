WITH joined_data AS (
    SELECT
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        s.s_state,
        cc.cc_country,
        ib.ib_upper_bound,
        cs.cs_net_profit,
        ws.ws_net_profit,
        sr.sr_net_loss,
        wr.wr_net_loss,
        (COALESCE(cs.cs_net_profit, 0) + COALESCE(ws.ws_net_profit, 0) - COALESCE(sr.sr_net_loss, 0) - COALESCE(wr.wr_net_loss, 0)) AS total_profit
    FROM catalog_sales cs
    JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
    JOIN inventory i ON w.w_warehouse_sk = i.inv_warehouse_sk
    JOIN customer c ON cs.cs_bill_customer_sk = c.c_customer_sk
    JOIN customer_demographics cd ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    LEFT JOIN store_returns sr ON sr.sr_customer_sk = c.c_customer_sk
    LEFT JOIN store s ON sr.sr_store_sk = s.s_store_sk
    LEFT JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
    LEFT JOIN web_sales ws ON ws.ws_bill_customer_sk = c.c_customer_sk
    LEFT JOIN web_returns wr ON wr.wr_order_number = ws.ws_order_number
    WHERE cc.cc_country = 'United States'
      AND s.s_state = 'CA'
      AND ib.ib_upper_bound >= 100000
),
customer_profit AS (
    SELECT
        c_customer_sk,
        c_first_name,
        c_last_name,
        s_state,
        SUM(total_profit) AS sum_profit,
        COUNT(*) AS txn_count,
        CASE WHEN SUM(total_profit) > 0 THEN 'Profit' ELSE 'Loss' END AS profit_indicator
    FROM joined_data
    GROUP BY c_customer_sk, c_first_name, c_last_name, s_state
)
SELECT
    c_customer_sk,
    c_first_name,
    c_last_name,
    s_state,
    sum_profit,
    txn_count,
    profit_indicator,
    RANK() OVER (ORDER BY sum_profit DESC) AS profit_rank,
    SUM(sum_profit) OVER () AS total_profit_all_customers
FROM customer_profit
ORDER BY sum_profit DESC
LIMIT 100

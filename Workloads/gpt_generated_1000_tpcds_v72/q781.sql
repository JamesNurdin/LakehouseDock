WITH all_sales AS (
    SELECT
        cs.cs_sold_date_sk               AS sold_date_sk,
        cs.cs_net_profit                  AS net_profit,
        cs.cs_net_paid                    AS net_paid,
        cs.cs_ship_mode_sk                AS ship_mode_sk,
        cs.cs_warehouse_sk                AS warehouse_sk,
        cs.cs_bill_hdemo_sk               AS demo_sk,
        cs.cs_bill_customer_sk            AS customer_sk,
        hd.hd_income_band_sk              AS income_band_sk,
        ib.ib_upper_bound                 AS income_upper,
        sm.sm_type                        AS ship_type,
        w.w_warehouse_name                AS warehouse_name,
        c.c_preferred_cust_flag           AS preferred_flag
    FROM catalog_sales cs
    JOIN customer c
        ON cs.cs_bill_customer_sk = c.c_customer_sk
    JOIN household_demographics hd
        ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib
        ON hd.hd_income_band_sk = ib.ib_income_band_sk
    JOIN ship_mode sm
        ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN warehouse w
        ON cs.cs_warehouse_sk = w.w_warehouse_sk
    WHERE cs.cs_quantity > 1
      AND cs.cs_net_profit IS NOT NULL
      AND ib.ib_upper_bound >= 50000
      AND sm.sm_type IN ('OVERNIGHT', 'EXPRESS')
      AND w.w_state = 'CA'
      AND c.c_preferred_cust_flag = 'Y'

    UNION ALL

    SELECT
        ws.ws_sold_date_sk               AS sold_date_sk,
        ws.ws_net_profit                  AS net_profit,
        ws.ws_net_paid                    AS net_paid,
        ws.ws_ship_mode_sk                AS ship_mode_sk,
        ws.ws_warehouse_sk                AS warehouse_sk,
        ws.ws_bill_hdemo_sk               AS demo_sk,
        ws.ws_bill_customer_sk            AS customer_sk,
        hd.hd_income_band_sk              AS income_band_sk,
        ib.ib_upper_bound                 AS income_upper,
        sm.sm_type                        AS ship_type,
        w.w_warehouse_name                AS warehouse_name,
        c.c_preferred_cust_flag           AS preferred_flag
    FROM web_sales ws
    JOIN customer c
        ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN household_demographics hd
        ON ws.ws_bill_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib
        ON hd.hd_income_band_sk = ib.ib_income_band_sk
    JOIN ship_mode sm
        ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN warehouse w
        ON ws.ws_warehouse_sk = w.w_warehouse_sk
    WHERE ws.ws_quantity > 1
      AND ws.ws_net_profit IS NOT NULL
      AND ib.ib_upper_bound >= 50000
      AND sm.sm_type IN ('OVERNIGHT', 'EXPRESS')
      AND w.w_state = 'CA'
      AND c.c_preferred_cust_flag = 'Y'
),
aggregated AS (
    SELECT
        income_band_sk,
        ship_type,
        SUM(net_profit)                         AS total_profit,
        SUM(net_paid)                           AS total_paid,
        CASE WHEN SUM(net_profit) > 100000 THEN 'High' ELSE 'Low' END AS profit_category
    FROM all_sales
    GROUP BY ROLLUP (income_band_sk, ship_type)
)
SELECT
    income_band_sk,
    ship_type,
    total_profit,
    total_paid,
    profit_category,
    RANK() OVER (PARTITION BY income_band_sk ORDER BY total_profit DESC) AS profit_rank
FROM aggregated
WHERE (income_band_sk IS NOT NULL OR ship_type IS NOT NULL)
ORDER BY income_band_sk NULLS LAST, profit_rank
LIMIT 100

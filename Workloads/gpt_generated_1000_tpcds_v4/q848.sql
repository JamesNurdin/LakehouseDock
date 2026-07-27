WITH base AS (
    SELECT
        d.d_year,
        d.d_month_seq,
        s.s_store_name,
        ss.ss_quantity AS ss_quantity,
        ss.ss_net_profit AS ss_net_profit,
        cs.cs_quantity AS cs_quantity,
        cs.cs_net_profit AS cs_net_profit,
        ws.ws_quantity AS ws_quantity,
        ws.ws_net_profit AS ws_net_profit,
        hd_ss.hd_income_band_sk AS ss_income_band,
        hd_cs.hd_income_band_sk AS cs_income_band,
        hd_ws.hd_income_band_sk AS ws_income_band,
        w_cs.w_warehouse_name AS cs_warehouse_name,
        w_ws.w_warehouse_name AS ws_warehouse_name
    FROM tpcds.date_dim d
    JOIN tpcds.store_sales ss
        ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN tpcds.household_demographics hd_ss
        ON ss.ss_hdemo_sk = hd_ss.hd_demo_sk
    JOIN tpcds.store s
        ON s.s_closed_date_sk = d.d_date_sk
    JOIN tpcds.catalog_sales cs
        ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN tpcds.household_demographics hd_cs
        ON cs.cs_bill_hdemo_sk = hd_cs.hd_demo_sk
    JOIN tpcds.warehouse w_cs
        ON cs.cs_warehouse_sk = w_cs.w_warehouse_sk
    JOIN tpcds.web_sales ws
        ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN tpcds.household_demographics hd_ws
        ON ws.ws_bill_hdemo_sk = hd_ws.hd_demo_sk
    JOIN tpcds.warehouse w_ws
        ON ws.ws_warehouse_sk = w_ws.w_warehouse_sk
    WHERE d.d_year = 2001
      AND d.d_month_seq BETWEEN 1200 AND 1212
      AND s.s_state = 'TN'
      AND hd_ss.hd_vehicle_count >= 2
      AND w_cs.w_city = 'Seattle'
)
SELECT
    base.s_store_name,
    base.d_year,
    SUM(base.ss_net_profit + base.cs_net_profit + base.ws_net_profit) AS total_profit,
    AVG(base.ss_quantity + base.cs_quantity + base.ws_quantity) AS avg_quantity
FROM base
GROUP BY base.s_store_name, base.d_year
HAVING SUM(base.ss_net_profit + base.cs_net_profit + base.ws_net_profit) > 10000
ORDER BY total_profit DESC
LIMIT 100

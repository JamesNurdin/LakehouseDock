WITH base AS (
    SELECT
        ss.ss_sold_date_sk,
        ss.ss_store_sk,
        ss.ss_cdemo_sk,
        ss.ss_ticket_number,
        ss.ss_quantity AS ss_quantity,
        ss.ss_ext_sales_price AS ss_ext_sales_price,
        ss.ss_net_profit AS ss_net_profit,
        ss.ss_ext_discount_amt AS ss_ext_discount_amt,
        sr.sr_return_quantity,
        sr.sr_return_amt,
        ws.ws_quantity AS ws_quantity,
        ws.ws_ext_sales_price AS ws_ext_sales_price,
        ws.ws_net_profit AS ws_net_profit,
        cp.cp_department,
        d.d_year,
        s.s_state,
        sm.sm_type,
        w.w_zip,
        c.cd_demo_sk
    FROM store_sales ss
    JOIN date_dim d
        ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN customer_demographics c
        ON ss.ss_cdemo_sk = c.cd_demo_sk
    JOIN store s
        ON ss.ss_store_sk = s.s_store_sk
    LEFT JOIN store_returns sr
        ON sr.sr_ticket_number = ss.ss_ticket_number
        AND sr.sr_item_sk = ss.ss_item_sk
        AND sr.sr_store_sk = s.s_store_sk
    LEFT JOIN web_sales ws
        ON ws.ws_sold_date_sk = d.d_date_sk
        AND ws.ws_bill_cdemo_sk = c.cd_demo_sk
    LEFT JOIN ship_mode sm
        ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
    LEFT JOIN warehouse w
        ON ws.ws_warehouse_sk = w.w_warehouse_sk
    LEFT JOIN catalog_page cp
        ON cp.cp_start_date_sk = d.d_date_sk
    WHERE d.d_year = 2001
      AND s.s_state = 'TX'
      AND w.w_zip = '19231'
      AND sm.sm_type = 'AIR'
      AND cp.cp_department = 'Sports'
      AND c.cd_gender = 'M'
)
SELECT
    s_state,
    sm_type,
    d_year,
    SUM(ss_ext_sales_price) AS total_store_sales,
    SUM(ws_ext_sales_price) AS total_web_sales,
    SUM(COALESCE(sr_return_amt, 0)) AS total_returns,
    SUM(ss_net_profit + ws_net_profit - COALESCE(sr_return_amt, 0)) AS net_profit,
    AVG(ss_ext_discount_amt) AS avg_store_discount,
    COUNT(DISTINCT cd_demo_sk) AS distinct_customers,
    SUM(CASE WHEN sr_return_quantity IS NULL THEN ss_quantity ELSE ss_quantity - sr_return_quantity END) AS net_quantity_sold
FROM base
GROUP BY GROUPING SETS (
    (s_state, sm_type, d_year),
    (s_state, sm_type),
    (d_year),
    ()
)
ORDER BY total_store_sales DESC
LIMIT 100

WITH joined_data AS (
    SELECT
        sm.sm_ship_mode_id,
        sm.sm_type,
        wp.wp_type,
        cs.cs_net_profit,
        ws.ws_net_profit,
        cs.cs_ext_discount_amt,
        ws.ws_ext_discount_amt,
        cs.cs_sales_price,
        cs.cs_quantity,
        cs.cs_ext_wholesale_cost,
        ws.ws_ext_ship_cost,
        ws.ws_ship_date_sk,
        hd_cs.hd_income_band_sk,
        sm.sm_contract
    FROM tpcds.ship_mode sm
    JOIN tpcds.catalog_sales cs
        ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN tpcds.household_demographics hd_cs
        ON cs.cs_bill_hdemo_sk = hd_cs.hd_demo_sk
    JOIN tpcds.web_sales ws
        ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN tpcds.household_demographics hd_ws
        ON ws.ws_bill_hdemo_sk = hd_ws.hd_demo_sk
    JOIN tpcds.web_page wp
        ON ws.ws_web_page_sk = wp.wp_web_page_sk
    WHERE cs.cs_sales_price > 100                      -- predicate 1
      AND cs.cs_quantity >= 2                         -- predicate 2
      AND cs.cs_ext_wholesale_cost BETWEEN 1200 AND 2500   -- predicate 3
      AND ws.ws_ext_ship_cost < 500                   -- predicate 4
      AND ws.ws_ship_date_sk BETWEEN 2451400 AND 2451500 -- predicate 5
      AND hd_cs.hd_income_band_sk IN (1, 2)           -- predicate 6
      AND sm.sm_contract LIKE 'P7F%'                 -- predicate 7
      AND wp.wp_type = 'content'                     -- predicate 8
),
aggregated AS (
    SELECT
        sm_ship_mode_id,
        sm_type,
        wp_type,
        SUM(cs_net_profit) AS catalog_profit,
        SUM(ws_net_profit) AS web_profit,
        AVG(cs_ext_discount_amt) AS avg_catalog_discount,
        AVG(ws_ext_discount_amt) AS avg_web_discount
    FROM joined_data
    GROUP BY sm_ship_mode_id, sm_type, wp_type
)
SELECT
    sm_ship_mode_id,
    sm_type,
    wp_type,
    catalog_profit,
    web_profit,
    (catalog_profit + web_profit) AS total_net_profit,
    avg_catalog_discount,
    avg_web_discount,
    RANK() OVER (PARTITION BY wp_type ORDER BY (catalog_profit + web_profit) DESC) AS profit_rank
FROM aggregated
ORDER BY total_net_profit DESC
LIMIT 100

WITH sampled_ship_mode AS (
    SELECT * FROM ship_mode TABLESAMPLE BERNOULLI (10)
),
cust_both AS (
    SELECT cs_bill_customer_sk AS cust_sk FROM catalog_sales
    INTERSECT
    SELECT ws_bill_customer_sk FROM web_sales
),
catalog_join AS (
    SELECT
        cs.cs_order_number,
        cs.cs_bill_customer_sk,
        cs.cs_sold_time_sk,
        cs.cs_net_profit,
        cs.cs_quantity,
        cp.cp_department,
        sm.sm_ship_mode_id,
        ca_bill.ca_state AS bill_state,
        ca_ship.ca_state AS ship_state,
        cd_bill.cd_gender,
        hd_bill.hd_buy_potential,
        ib.ib_upper_bound AS income_upper,
        t.t_hour,
        CASE WHEN cs.cs_quantity > 5 THEN 'Bulk' ELSE 'Regular' END AS qty_category,
        l.total_ext_price
    FROM catalog_sales cs
    JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN sampled_ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN household_demographics hd_bill ON cs.cs_bill_hdemo_sk = hd_bill.hd_demo_sk
    LEFT JOIN income_band ib ON hd_bill.hd_income_band_sk = ib.ib_income_band_sk
    JOIN customer_address ca_bill ON cs.cs_bill_addr_sk = ca_bill.ca_address_sk
    JOIN customer_address ca_ship ON cs.cs_ship_addr_sk = ca_ship.ca_address_sk
    JOIN customer_demographics cd_bill ON cs.cs_bill_cdemo_sk = cd_bill.cd_demo_sk
    JOIN customer_demographics cd_ship ON cs.cs_ship_cdemo_sk = cd_ship.cd_demo_sk
    JOIN time_dim t ON cs.cs_sold_time_sk = t.t_time_sk
    JOIN household_demographics hd_ship ON cs.cs_ship_hdemo_sk = hd_ship.hd_demo_sk
    CROSS JOIN LATERAL (
        SELECT sum(cs2.cs_ext_sales_price) AS total_ext_price
        FROM catalog_sales cs2
        WHERE cs2.cs_order_number = cs.cs_order_number
          AND cs2.cs_ship_mode_sk = sm.sm_ship_mode_sk
    ) l
    WHERE cs.cs_bill_customer_sk IN (SELECT cust_sk FROM cust_both)
)
SELECT
    c.cp_department,
    c.sm_ship_mode_id,
    c.qty_category,
    c.income_upper,
    SUM(c.cs_net_profit) AS catalog_profit,
    SUM(w.ws_net_profit) AS web_profit,
    SUM(c.cs_net_profit) + SUM(w.ws_net_profit) AS total_profit
FROM catalog_join c
JOIN web_sales w ON w.ws_bill_customer_sk = c.cs_bill_customer_sk
    AND w.ws_sold_time_sk = c.cs_sold_time_sk
JOIN web_page wp ON w.ws_web_page_sk = wp.wp_web_page_sk
LEFT JOIN sampled_ship_mode sm2 ON w.ws_ship_mode_sk = sm2.sm_ship_mode_sk
GROUP BY ROLLUP (c.cp_department, c.sm_ship_mode_id, c.qty_category, c.income_upper)
HAVING SUM(c.cs_net_profit) > 0
ORDER BY total_profit DESC
LIMIT 100

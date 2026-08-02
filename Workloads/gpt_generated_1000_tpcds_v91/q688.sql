/*
  Goal: Analyze net profit across catalog and web sales by customer gender and warehouse location, 
  including inventory quantities and per‑warehouse profit benchmarks, while demonstrating deep joins, 
  table reuse under multiple aliases, a CTE, correlated subqueries, and a ROLLUP aggregation.
*/
WITH ws_w AS (
    SELECT
        ws.ws_sold_time_sk,
        ws.ws_bill_customer_sk,
        ws.ws_ship_customer_sk,
        ws.ws_net_profit,
        ws.ws_warehouse_sk,
        w.w_state,
        w.w_warehouse_sk AS w_sk,
        ws.ws_web_page_sk
    FROM web_sales ws
    JOIN warehouse w
        ON ws.ws_warehouse_sk = w.w_warehouse_sk
)
SELECT
    cd_bill.cd_gender,
    ws_w.w_state,
    ws_w.w_sk,
    sum(cs.cs_net_profit) AS total_catalog_net_profit,
    sum(ws_w.ws_net_profit) AS total_web_net_profit,
    sum(i.inv_quantity_on_hand) AS total_inventory_qty,
    (
        SELECT max(ws2.ws_net_profit)
        FROM web_sales ws2
        WHERE ws2.ws_warehouse_sk = ws_w.w_sk
    ) AS max_ws_profit_by_warehouse,
    (
        SELECT avg(cs2.cs_net_profit)
        FROM catalog_sales cs2
        WHERE cs2.cs_warehouse_sk = ws_w.w_sk
    ) AS avg_cs_profit_by_warehouse
FROM catalog_sales cs
JOIN time_dim t
    ON cs.cs_sold_time_sk = t.t_time_sk
JOIN customer cust_bill
    ON cs.cs_bill_customer_sk = cust_bill.c_customer_sk
JOIN customer cust_ship
    ON cs.cs_ship_customer_sk = cust_ship.c_customer_sk
JOIN customer_demographics cd_bill
    ON cs.cs_bill_cdemo_sk = cd_bill.cd_demo_sk
JOIN customer_demographics cd_ship
    ON cs.cs_ship_cdemo_sk = cd_ship.cd_demo_sk
JOIN household_demographics hd_bill
    ON cs.cs_bill_hdemo_sk = hd_bill.hd_demo_sk
JOIN household_demographics hd_ship
    ON cs.cs_ship_hdemo_sk = hd_ship.hd_demo_sk
JOIN customer_demographics cd_current
    ON cust_bill.c_current_cdemo_sk = cd_current.cd_demo_sk
JOIN household_demographics hd_current
    ON cust_bill.c_current_hdemo_sk = hd_current.hd_demo_sk
JOIN warehouse w_cs
    ON cs.cs_warehouse_sk = w_cs.w_warehouse_sk
JOIN inventory i
    ON w_cs.w_warehouse_sk = i.inv_warehouse_sk
JOIN ws_w
    ON ws_w.ws_sold_time_sk = t.t_time_sk
    AND ws_w.ws_bill_customer_sk = cust_bill.c_customer_sk
JOIN web_page wp
    ON ws_w.ws_web_page_sk = wp.wp_web_page_sk
JOIN customer cust_wp
    ON wp.wp_customer_sk = cust_wp.c_customer_sk
WHERE cs.cs_quantity > 0
  AND cs.cs_net_paid > (
      SELECT avg(cs2.cs_net_paid)
      FROM catalog_sales cs2
      WHERE cs2.cs_bill_customer_sk = cust_bill.c_customer_sk
  )
GROUP BY ROLLUP (cd_bill.cd_gender, ws_w.w_state, ws_w.w_sk)
HAVING sum(cs.cs_net_profit) > 0
ORDER BY cd_bill.cd_gender, ws_w.w_state, ws_w.w_sk
LIMIT 100

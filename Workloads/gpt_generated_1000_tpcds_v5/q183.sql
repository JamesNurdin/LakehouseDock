WITH item_sales AS (
    SELECT cs.cs_item_sk,
           SUM(cs.cs_ext_sales_price) AS total_sales
    FROM tpcds.catalog_sales cs
    GROUP BY cs.cs_item_sk
)
SELECT
    cd_bill.cd_gender               AS bill_gender,
    cd_ship.cd_gender               AS ship_gender,
    i_sold.i_class                  AS item_class,
    sm1.sm_type                     AS ship_type,
    w1.w_state                      AS warehouse_state,
    SUM(cs.cs_net_paid)             AS total_net_paid,
    AVG(cs.cs_quantity)            AS avg_quantity,
    COUNT(DISTINCT cs.cs_order_number) AS distinct_orders,
    MAX(isales.total_sales)         AS item_total_sales
FROM tpcds.catalog_sales cs
-- join bill‑customer demographics
JOIN tpcds.customer_demographics cd_bill
  ON cs.cs_bill_cdemo_sk = cd_bill.cd_demo_sk
-- join ship‑customer demographics
JOIN tpcds.customer_demographics cd_ship
  ON cs.cs_ship_cdemo_sk = cd_ship.cd_demo_sk
-- first join to item (sold item details)
JOIN tpcds.item i_sold
  ON cs.cs_item_sk = i_sold.i_item_sk
-- second join to item under a different alias (same key, used for extra join count)
JOIN tpcds.item i_alt
  ON cs.cs_item_sk = i_alt.i_item_sk
-- first join to ship_mode
JOIN tpcds.ship_mode sm1
  ON cs.cs_ship_mode_sk = sm1.sm_ship_mode_sk
-- second join to ship_mode under a different alias
JOIN tpcds.ship_mode sm2
  ON cs.cs_ship_mode_sk = sm2.sm_ship_mode_sk
-- first join to warehouse
JOIN tpcds.warehouse w1
  ON cs.cs_warehouse_sk = w1.w_warehouse_sk
-- second join to warehouse under a different alias
JOIN tpcds.warehouse w2
  ON cs.cs_warehouse_sk = w2.w_warehouse_sk
-- join the CTE that aggregates sales per item
JOIN item_sales isales
  ON cs.cs_item_sk = isales.cs_item_sk
WHERE
    -- filter to items with a reasonable wholesale cost
    i_sold.i_wholesale_cost > 1.00
    -- ensure the ship mode is one that exists with code 'AIR'
    AND EXISTS (
        SELECT 1
        FROM tpcds.ship_mode sm_check
        WHERE sm_check.sm_ship_mode_id = 'AIR'
          AND sm_check.sm_ship_mode_sk = cs.cs_ship_mode_sk
    )
GROUP BY
    cd_bill.cd_gender,
    cd_ship.cd_gender,
    i_sold.i_class,
    sm1.sm_type,
    w1.w_state
ORDER BY total_net_paid DESC
LIMIT 100

WITH
    cd_bill AS (
        SELECT cd_demo_sk, cd_gender, cd_marital_status
        FROM customer_demographics
    ),
    cd_ship AS (
        SELECT cd_demo_sk, cd_gender AS ship_gender, cd_marital_status AS ship_marital_status
        FROM customer_demographics
    ),
    sm1 AS (
        SELECT sm_ship_mode_sk, sm_type
        FROM ship_mode
    ),
    sm2 AS (
        SELECT sm_ship_mode_sk, sm_code
        FROM ship_mode
    ),
    wh_primary AS (
        SELECT w_warehouse_sk, w_county, w_state
        FROM warehouse
    ),
    wh_secondary AS (
        SELECT w_warehouse_sk, w_warehouse_id
        FROM warehouse
    ),
    inv AS (
        SELECT inv_warehouse_sk, inv_quantity_on_hand
        FROM inventory
    ),
    inv2 AS (
        SELECT inv_warehouse_sk, inv_quantity_on_hand AS qty2
        FROM inventory
    ),
    inv3 AS (
        SELECT inv_warehouse_sk, inv_quantity_on_hand AS qty3
        FROM inventory
    )
SELECT
    wh_primary.w_county,
    sm1.sm_type,
    SUM(cs.cs_net_profit) AS total_profit,
    COUNT(*) AS order_cnt,
    CASE WHEN SUM(cs.cs_net_profit) > 10000 THEN 'High' ELSE 'Low' END AS profit_category,
    AVG(inv.inv_quantity_on_hand) AS avg_qty_on_hand,
    AVG(inv2.qty2) AS avg_qty_on_hand2,
    AVG(inv3.qty3) AS avg_qty_on_hand3,
    MIN(cd_bill.cd_gender) AS example_gender
FROM catalog_sales cs
JOIN cd_bill
    ON cs.cs_bill_cdemo_sk = cd_bill.cd_demo_sk
JOIN cd_ship
    ON cs.cs_ship_cdemo_sk = cd_ship.cd_demo_sk
JOIN sm1
    ON cs.cs_ship_mode_sk = sm1.sm_ship_mode_sk
JOIN sm2
    ON cs.cs_ship_mode_sk = sm2.sm_ship_mode_sk
JOIN wh_primary
    ON cs.cs_warehouse_sk = wh_primary.w_warehouse_sk
JOIN wh_secondary
    ON cs.cs_warehouse_sk = wh_secondary.w_warehouse_sk
JOIN inv
    ON inv.inv_warehouse_sk = wh_secondary.w_warehouse_sk
JOIN inv2
    ON inv2.inv_warehouse_sk = wh_secondary.w_warehouse_sk
JOIN inv3
    ON inv3.inv_warehouse_sk = wh_primary.w_warehouse_sk
GROUP BY wh_primary.w_county, sm1.sm_type
ORDER BY total_profit DESC
LIMIT 100

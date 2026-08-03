WITH base AS (
    SELECT
        cs.cs_order_number,
        cs.cs_bill_customer_sk,
        c.c_customer_id,
        cs.cs_item_sk,
        i.i_item_id,
        sm.sm_ship_mode_id,
        cs.cs_ext_sales_price,
        cs.cs_net_profit,
        cs.cs_ext_wholesale_cost,
        cs.cs_ext_discount_amt,
        inv.inv_warehouse_sk
    FROM catalog_sales cs
    JOIN customer c
      ON cs.cs_bill_customer_sk = c.c_customer_sk
    JOIN ship_mode sm
      ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN item i
      ON cs.cs_item_sk = i.i_item_sk
    JOIN inventory inv
      ON inv.inv_item_sk = i.i_item_sk
    WHERE cs.cs_promo_sk IN (397, 462, 284)
      AND cs.cs_ext_wholesale_cost > 2000
      AND sm.sm_carrier = 'USPS'
      AND inv.inv_warehouse_sk = 15
),
agg1 AS (
    SELECT
        c_customer_id,
        i_item_id,
        sm_ship_mode_id,
        COUNT(DISTINCT cs_order_number) AS orders_cnt,
        SUM(cs_ext_sales_price) AS total_sales,
        SUM(cs_net_profit) AS total_profit,
        CASE WHEN SUM(cs_net_profit) > 0 THEN 'POS' ELSE 'NEG' END AS profit_flag
    FROM base
    GROUP BY c_customer_id, i_item_id, sm_ship_mode_id
    HAVING COUNT(DISTINCT cs_order_number) >= 2
)
SELECT
    profit_flag,
    COUNT(*) AS customer_item_groups,
    AVG(total_sales) AS avg_sales_per_group,
    MAX(total_profit) AS max_profit
FROM agg1
WHERE c_customer_id NOT IN (
    SELECT c2.c_customer_id
    FROM customer c2
    WHERE c2.c_preferred_cust_flag = 'Y'
)
GROUP BY profit_flag
ORDER BY avg_sales_per_group DESC
LIMIT 100

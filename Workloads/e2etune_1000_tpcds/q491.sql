WITH sales_state AS (
    SELECT
        ca.ca_state,
        SUM(ss.ss_net_profit) AS total_profit,
        AVG(ss.ss_ext_discount_amt) AS avg_discount,
        COUNT(DISTINCT ss.ss_customer_sk) AS cust_cnt,
        ROW_NUMBER() OVER (ORDER BY SUM(ss.ss_net_profit) DESC) AS profit_rank
    FROM store_sales ss
    JOIN customer_address ca
        ON ss.ss_addr_sk = ca.ca_address_sk
    WHERE ca.ca_country = 'United States'
      AND ca.ca_gmt_offset = -5.00
    GROUP BY ca.ca_state
),
inventory_state AS (
    SELECT
        w.w_state,
        SUM(inv.inv_quantity_on_hand) AS total_qty,
        COUNT(DISTINCT inv.inv_item_sk) AS distinct_items,
        ROW_NUMBER() OVER (ORDER BY SUM(inv.inv_quantity_on_hand) DESC) AS inventory_rank
    FROM inventory inv
    JOIN warehouse w
        ON inv.inv_warehouse_sk = w.w_warehouse_sk
    WHERE w.w_country = 'United States'
    GROUP BY w.w_state
)
SELECT
    'sales' AS source,
    ca_state AS state,
    total_profit,
    avg_discount,
    cust_cnt,
    profit_rank,
    NULL AS total_qty,
    NULL AS distinct_items,
    NULL AS inventory_rank
FROM sales_state
UNION ALL
SELECT
    'inventory' AS source,
    w_state AS state,
    NULL AS total_profit,
    NULL AS avg_discount,
    NULL AS cust_cnt,
    NULL AS profit_rank,
    total_qty,
    distinct_items,
    inventory_rank
FROM inventory_state
ORDER BY source, state

/*
Goal: Identify the top‑ranked customers by total catalog sales amount, enriched with household income band, store, warehouse and web‑sales characteristics, while demonstrating advanced Trino features such as CTE aggregation, TABLESAMPLE, UNION, EXCEPT, LATERAL, window functions, CASE logic, correlated subqueries and set operations.
*/
WITH
    -- Aggregate catalog sales per item and order (pre‑aggregation before the main join)
    cte_sales_agg AS (
        SELECT
            cs_item_sk,
            cs_order_number,
            SUM(cs_ext_sales_price) AS total_sales_price,
            SUM(cs_quantity)        AS total_quantity,
            AVG(cs_sales_price)     AS avg_sales_price
        FROM catalog_sales
        WHERE cs_quantity > 5
        GROUP BY cs_item_sk, cs_order_number
    ),
    -- Sample a portion of the inventory table
    cte_inventory_sampled AS (
        SELECT *
        FROM inventory TABLESAMPLE BERNOULLI (10)  -- roughly 10 % of rows
    ),
    -- Orders that have a sale but no corresponding return (EXCEPT example)
    cte_orders_without_returns AS (
        SELECT cs_order_number
        FROM catalog_sales
        EXCEPT
        SELECT cr_order_number
        FROM catalog_returns
    ),
    -- Union of sales and returns rows to force a distinct‑set aggregation later
    cte_union AS (
        SELECT
            cs.cs_item_sk   AS item_sk,
            cs.cs_order_number AS order_number,
            cs.cs_quantity   AS qty,
            cs.cs_ext_sales_price AS amount,
            'sales'   AS src
        FROM catalog_sales cs
        WHERE cs.cs_quantity > 5
        UNION
        SELECT
            cr.cr_item_sk   AS item_sk,
            cr.cr_order_number AS order_number,
            cr.cr_return_quantity  AS qty,
            cr.cr_return_amount    AS amount,
            'returns' AS src
        FROM catalog_returns cr
        WHERE cr.cr_return_quantity > 5
    )
SELECT
    c.c_customer_id,
    hd.hd_income_band_sk,
    ib.ib_lower_bound,
    ib.ib_upper_bound,
    s.s_store_name,
    sm.sm_carrier,
    w.w_warehouse_name,
    CASE
        WHEN ws.ws_quantity IS NULL               THEN 'NoWeb'
        WHEN ws.ws_quantity > 10                  THEN 'HighWeb'
        ELSE                                           'LowWeb'
    END AS web_quantity_category,
    ca.total_sales_price,
    ca.total_quantity,
    ca.avg_sales_price,
    cs_l.item_total,
    ROW_NUMBER() OVER (PARTITION BY c.c_customer_id ORDER BY ca.total_sales_price DESC) AS sales_rank,
    (
        SELECT COUNT(*)
        FROM store_returns sr2
        WHERE sr2.sr_customer_sk = c.c_customer_sk
          AND sr2.sr_returned_date_sk > 20200101
    ) AS recent_return_cnt
FROM cte_union u
JOIN cte_sales_agg ca
      ON ca.cs_item_sk = u.item_sk
     AND ca.cs_order_number = u.order_number
JOIN catalog_sales cs
      ON cs.cs_item_sk = ca.cs_item_sk
     AND cs.cs_order_number = ca.cs_order_number
JOIN LATERAL (
    SELECT SUM(cs2.cs_ext_sales_price) AS item_total
    FROM catalog_sales cs2
    WHERE cs2.cs_item_sk = cs.cs_item_sk
) cs_l ON TRUE
JOIN catalog_returns cr
      ON cr.cr_order_number = cs.cs_order_number
JOIN customer c
      ON c.c_customer_sk = cr.cr_refunded_customer_sk
      AND cs.cs_bill_customer_sk = c.c_customer_sk   -- explicit join rule
JOIN household_demographics hd
      ON hd.hd_demo_sk = c.c_current_hdemo_sk
JOIN income_band ib
      ON ib.ib_income_band_sk = hd.hd_income_band_sk
JOIN store_returns sr
      ON sr.sr_customer_sk = c.c_customer_sk
     AND sr.sr_hdemo_sk = hd.hd_demo_sk            -- join rule for store_returns
JOIN store s
      ON s.s_store_sk = sr.sr_store_sk
JOIN ship_mode sm
      ON sm.sm_ship_mode_sk = cs.cs_ship_mode_sk
JOIN warehouse w
      ON w.w_warehouse_sk = cs.cs_warehouse_sk
JOIN web_sales ws
      ON ws.ws_bill_customer_sk = c.c_customer_sk
LEFT JOIN cte_inventory_sampled inv
       ON inv.inv_item_sk = cs.cs_item_sk
      AND inv.inv_warehouse_sk = w.w_warehouse_sk
WHERE
    cr.cr_return_amount > 50
    AND ca.total_sales_price > 1000
    AND ib.ib_lower_bound >= 40000
    AND cs.cs_order_number IN (SELECT cs_order_number FROM cte_orders_without_returns)
    AND EXISTS (
        SELECT 1
        FROM store_returns sr3
        WHERE sr3.sr_customer_sk = c.c_customer_sk
          AND sr3.sr_return_quantity > 0
    )
ORDER BY ca.total_sales_price DESC
LIMIT 100

/*
Goal: Produce a deep‑join analytical view that combines catalog sales, returns, web returns, warehouse, reason and demographic/address dimensions. The query aggregates sales per order, classifies sales volume, calculates total web‑return amount via a correlated sub‑query, ranks orders within each warehouse, and limits the output to the top 100 rows.
*/
WITH sales_agg AS (
    SELECT
        cs.cs_order_number,
        SUM(cs.cs_ext_sales_price)           AS total_sales_price,
        SUM(cs.cs_quantity)                  AS total_quantity,
        MAX(cs.cs_warehouse_sk)              AS warehouse_sk,
        MAX(cs.cs_bill_hdemo_sk)             AS bill_hdemo_sk,
        MAX(cs.cs_ship_hdemo_sk)             AS ship_hdemo_sk,
        MAX(cs.cs_bill_addr_sk)              AS bill_addr_sk,
        MAX(cs.cs_ship_addr_sk)              AS ship_addr_sk
    FROM catalog_sales cs
    TABLESAMPLE BERNOULLI (10)          -- sample 10 % of the sales table
    GROUP BY cs.cs_order_number
)
SELECT
    sa.cs_order_number                               AS order_number,
    sa.total_sales_price,
    sa.total_quantity,
    w.w_warehouse_name,
    r.r_reason_desc,
    CASE
        WHEN sa.total_sales_price > 10000 THEN 'High'
        WHEN sa.total_sales_price > 5000  THEN 'Medium'
        ELSE 'Low'
    END                                            AS sales_category,
    (
        SELECT COALESCE(SUM(wr.wr_return_amt), 0)
        FROM web_returns wr
        WHERE wr.wr_order_number = sa.cs_order_number
    )                                               AS total_web_return_amount,
    COUNT(DISTINCT wr.wr_return_quantity)          AS web_return_quantity_cnt,
    ROW_NUMBER() OVER (
        PARTITION BY w.w_warehouse_name
        ORDER BY sa.total_sales_price DESC
    )                                               AS warehouse_sales_rank
FROM sales_agg sa
-- Join catalog returns (mandatory link)
JOIN catalog_returns cr
    ON cr.cr_order_number = sa.cs_order_number
-- Warehouse of the return
JOIN warehouse w
    ON w.w_warehouse_sk = cr.cr_warehouse_sk
-- Reason for the return
JOIN reason r
    ON r.r_reason_sk = cr.cr_reason_sk
-- Demographics & address for the returning customer (returning side)
JOIN household_demographics hd_ret
    ON hd_ret.hd_demo_sk = cr.cr_returning_hdemo_sk
JOIN customer_address ca_ret
    ON ca_ret.ca_address_sk = cr.cr_returning_addr_sk
-- Demographics & address for the refunded customer (refunded side)
JOIN household_demographics hd_ref
    ON hd_ref.hd_demo_sk = cr.cr_refunded_hdemo_sk
JOIN customer_address ca_ref
    ON ca_ref.ca_address_sk = cr.cr_refunded_addr_sk
-- Demographics & address from the original sale (billing side)
JOIN household_demographics hd_bill
    ON hd_bill.hd_demo_sk = sa.bill_hdemo_sk
JOIN customer_address ca_bill
    ON ca_bill.ca_address_sk = sa.bill_addr_sk
-- Demographics & address from the original sale (shipping side)
JOIN household_demographics hd_ship
    ON hd_ship.hd_demo_sk = sa.ship_hdemo_sk
JOIN customer_address ca_ship
    ON ca_ship.ca_address_sk = sa.ship_addr_sk
-- Join web_returns through the same reason (adds another join clause)
JOIN web_returns wr
    ON wr.wr_reason_sk = r.r_reason_sk
    AND wr.wr_refunded_hdemo_sk = hd_ref.hd_demo_sk
WHERE cr.cr_return_amount IS NOT NULL
GROUP BY
    sa.cs_order_number,
    sa.total_sales_price,
    sa.total_quantity,
    w.w_warehouse_name,
    r.r_reason_desc,
    hd_ret.hd_demo_sk,
    ca_ret.ca_address_sk,
    hd_ref.hd_demo_sk,
    ca_ref.ca_address_sk,
    hd_bill.hd_demo_sk,
    ca_bill.ca_address_sk,
    hd_ship.hd_demo_sk,
    ca_ship.ca_address_sk,
    w.w_warehouse_sk
ORDER BY sa.total_sales_price DESC
LIMIT 100

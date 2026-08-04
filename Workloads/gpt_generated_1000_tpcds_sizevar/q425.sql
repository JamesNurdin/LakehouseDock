WITH inv_wh AS (
    SELECT
        inv.inv_item_sk,
        inv.inv_warehouse_sk,
        inv.inv_quantity_on_hand,
        w.w_warehouse_name
    FROM inventory inv
    FULL OUTER JOIN warehouse w
        ON inv.inv_warehouse_sk = w.w_warehouse_sk
)
SELECT
    i.i_item_id           AS item_id,
    i.i_product_name      AS product_name,
    SUM(cs.cs_ext_sales_price) AS total_sales,
    0                     AS total_returns,
    CASE
        WHEN SUM(cs.cs_net_profit) / NULLIF(SUM(cs.cs_ext_sales_price), 0) > 0.20 THEN 'High'
        WHEN SUM(cs.cs_net_profit) / NULLIF(SUM(cs.cs_ext_sales_price), 0) > 0.10 THEN 'Medium'
        ELSE 'Low'
    END                  AS profit_category,
    'sales'               AS record_type
FROM catalog_sales cs
JOIN item i
    ON cs.cs_item_sk = i.i_item_sk
JOIN inv_wh iw
    ON cs.cs_item_sk = iw.inv_item_sk
WHERE cs.cs_sold_date_sk IN (
    SELECT inv_date_sk
    FROM inventory
    WHERE inv_quantity_on_hand > 0
)
GROUP BY i.i_item_id, i.i_product_name

UNION

SELECT
    i.i_item_id           AS item_id,
    i.i_product_name      AS product_name,
    0                     AS total_sales,
    SUM(wr.wr_return_amt) AS total_returns,
    CASE
        WHEN SUM(wr.wr_return_amt) > 1000 THEN 'High'
        WHEN SUM(wr.wr_return_amt) > 500  THEN 'Medium'
        ELSE 'Low'
    END                  AS profit_category,
    'return'              AS record_type
FROM web_returns wr
JOIN item i
    ON wr.wr_item_sk = i.i_item_sk
JOIN reason r
    ON wr.wr_reason_sk = r.r_reason_sk
WHERE i.i_item_sk IN (
    SELECT inv_item_sk
    FROM inventory
    WHERE inv_quantity_on_hand > 0
)
GROUP BY i.i_item_id, i.i_product_name

ORDER BY total_sales DESC, total_returns DESC
LIMIT 100

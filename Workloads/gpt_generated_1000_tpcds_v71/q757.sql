WITH rs AS (
    SELECT
        sr_item_sk,
        sr_reason_sk,
        SUM(sr_return_amt) AS total_return_amt,
        SUM(sr_return_quantity) AS total_return_qty,
        COUNT(*) AS return_cnt
    FROM store_returns
    WHERE sr_return_ship_cost > 0
      AND sr_return_quantity > 0
      AND sr_return_amt > 10
    GROUP BY sr_item_sk, sr_reason_sk
)
SELECT
    i.i_item_id,
    i.i_product_name,
    r.r_reason_desc,
    SUM(cs.cs_ext_sales_price) AS total_sales,
    rs.total_return_amt,
    CASE WHEN SUM(cs.cs_ext_sales_price) > rs.total_return_amt THEN 'Profit' ELSE 'Loss' END AS profit_indicator,
    COUNT(DISTINCT cs.cs_order_number) AS distinct_orders
FROM catalog_sales cs
JOIN item i ON cs.cs_item_sk = i.i_item_sk
JOIN rs ON rs.sr_item_sk = i.i_item_sk
JOIN reason r ON rs.sr_reason_sk = r.r_reason_sk
WHERE i.i_wholesale_cost BETWEEN 5 AND 20
  AND r.r_reason_id LIKE 'AAAA%'
  AND cs.cs_quantity >= 2
  AND NOT EXISTS (
        SELECT 1 FROM store_returns sr2
        WHERE sr2.sr_item_sk = i.i_item_sk
          AND sr2.sr_return_amt > 500
    )
GROUP BY i.i_item_id, i.i_product_name, r.r_reason_desc, rs.total_return_amt
HAVING SUM(cs.cs_ext_sales_price) > 1000
ORDER BY total_sales DESC
LIMIT 100

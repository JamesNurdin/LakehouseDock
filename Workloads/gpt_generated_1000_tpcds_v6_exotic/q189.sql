WITH filtered_sales AS (
    SELECT
        cs.cs_bill_customer_sk,
        cs.cs_ship_mode_sk,
        cs.cs_ext_sales_price,
        cs.cs_coupon_amt,
        cs.cs_ext_wholesale_cost,
        cs.cs_order_number,
        cs.cs_sold_date_sk
    FROM catalog_sales cs
    WHERE cs.cs_ext_wholesale_cost > 500
      AND cs.cs_coupon_amt < 1000
      AND cs.cs_sold_date_sk BETWEEN 2450000 AND 2450100
)
SELECT
    c.c_customer_id,
    sm.sm_ship_mode_id,
    COUNT(DISTINCT fs.cs_order_number) AS order_cnt,
    SUM(fs.cs_ext_sales_price) AS total_sales,
    AVG(fs.cs_coupon_amt) AS avg_coupon,
    SUM(sr.sr_return_amt) AS total_returns,
    MIN(fs.cs_ext_sales_price) AS min_sale,
    MAX(fs.cs_ext_sales_price) AS max_sale
FROM filtered_sales fs
JOIN customer c
  ON fs.cs_bill_customer_sk = c.c_customer_sk
LEFT JOIN ship_mode sm
  ON fs.cs_ship_mode_sk = sm.sm_ship_mode_sk
     AND sm.sm_type = 'AIR'      -- predicate pushed to ON to preserve outer‑join semantics
JOIN store_returns sr
  ON c.c_customer_sk = sr.sr_customer_sk
WHERE c.c_birth_month = 6
  AND sr.sr_return_quantity BETWEEN 5 AND 50
  AND NOT EXISTS (
        SELECT 1
        FROM store_returns sr2
        WHERE sr2.sr_customer_sk = c.c_customer_sk
          AND sr2.sr_return_amt > 1000
    )
GROUP BY c.c_customer_id, sm.sm_ship_mode_id
HAVING SUM(fs.cs_ext_sales_price) > 10000
   AND COUNT(DISTINCT fs.cs_order_number) > 5
ORDER BY total_sales DESC
LIMIT 100

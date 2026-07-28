/* Goal: Analyze total catalog sales and promotional costs for the 'dresses' class in 1998, filtering for high coupon amounts and wholesale cost range, and only for items that had at least one store return. The query returns detailed, yearly, and grand‑total subtotals using GROUPING SETS. */
WITH filtered_sales AS (
    SELECT
        cs.cs_sold_date_sk,
        cs.cs_item_sk,
        cs.cs_promo_sk,
        cs.cs_ext_sales_price,
        cs.cs_coupon_amt,
        cs.cs_wholesale_cost,
        cs.cs_order_number
    FROM catalog_sales cs
    WHERE cs.cs_coupon_amt > 500               -- high coupon amount
      AND cs.cs_wholesale_cost BETWEEN 10 AND 70   -- realistic wholesale cost range
)
SELECT
    dd.d_year,
    i.i_class,
    SUM(fs.cs_ext_sales_price)               AS total_sales,
    COUNT(DISTINCT fs.cs_order_number)        AS order_cnt,
    AVG(fs.cs_coupon_amt)                    AS avg_coupon,
    MIN(fs.cs_ext_sales_price)               AS min_sales,
    MAX(fs.cs_ext_sales_price)               AS max_sales,
    SUM(COALESCE(p.p_cost, 0))               AS total_promo_cost
FROM filtered_sales fs
JOIN date_dim dd
  ON fs.cs_sold_date_sk = dd.d_date_sk
JOIN item i
  ON fs.cs_item_sk = i.i_item_sk
LEFT JOIN promotion p
  ON fs.cs_promo_sk = p.p_promo_sk
  AND p.p_item_sk = i.i_item_sk
  AND p.p_discount_active = 'Y'               -- only active promotions
WHERE dd.d_year = 1998                         -- focus on year 1998
  AND i.i_class = 'dresses'                    -- specific product class
  AND EXISTS (
        SELECT 1
        FROM store_returns sr
        WHERE sr.sr_item_sk = i.i_item_sk
          AND sr.sr_returned_date_sk = dd.d_date_sk
          AND sr.sr_return_quantity > 0      -- at least one return
    )
GROUP BY GROUPING SETS (
        (dd.d_year, i.i_class),   -- detail per year & class
        (dd.d_year),              -- subtotal per year
        ()                         -- grand total
    )
ORDER BY total_sales DESC
LIMIT 100

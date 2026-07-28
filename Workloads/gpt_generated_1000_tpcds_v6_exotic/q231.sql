WITH sales_agg AS (
   SELECT
       cs.cs_item_sk,
       d.d_year,
       SUM(cs.cs_ext_sales_price) AS total_sales,
       SUM(cs.cs_quantity) AS total_qty,
       COUNT(*) AS sales_transactions
   FROM catalog_sales cs
   JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
   JOIN item i ON cs.cs_item_sk = i.i_item_sk
   WHERE d.d_year = 2000
     AND i.i_category = 'Electronics'
   GROUP BY cs.cs_item_sk, d.d_year
)
SELECT
    i.i_item_id,
    i.i_brand,
    d.d_year,
    p.p_promo_name,
    cp.cp_department,
    sa.total_sales,
    sa.total_qty,
    sa.sales_transactions,
    CASE
        WHEN sa.total_sales > 100000 THEN 'High'
        ELSE 'Normal'
    END AS sales_category,
    SUM(cr.cr_return_amount) AS total_return_amount,
    SUM(wr.wr_return_amt) AS total_web_return_amount
FROM sales_agg sa
JOIN catalog_sales cs ON cs.cs_item_sk = sa.cs_item_sk
JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
JOIN item i ON cs.cs_item_sk = i.i_item_sk
JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
LEFT JOIN catalog_returns cr ON cr.cr_order_number = cs.cs_order_number
    AND cr.cr_item_sk = cs.cs_item_sk
LEFT JOIN web_returns wr ON wr.wr_item_sk = cs.cs_item_sk
WHERE p.p_discount_active = 'Y'
  AND cp.cp_department = 'Books'
  AND NOT EXISTS (
        SELECT 1 FROM web_returns wr2
        WHERE wr2.wr_item_sk = cs.cs_item_sk
          AND wr2.wr_return_amt > 500
    )
GROUP BY
    i.i_item_id,
    i.i_brand,
    d.d_year,
    p.p_promo_name,
    cp.cp_department,
    sa.total_sales,
    sa.total_qty,
    sa.sales_transactions,
    CASE WHEN sa.total_sales > 100000 THEN 'High' ELSE 'Normal' END
HAVING sa.total_sales > 50000
ORDER BY sa.total_sales DESC
LIMIT 100

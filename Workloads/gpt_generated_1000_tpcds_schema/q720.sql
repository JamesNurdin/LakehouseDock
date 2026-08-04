WITH base AS (
    SELECT
        d.d_year,
        d.d_month_seq,
        ss.ss_item_sk AS ss_item_sk,
        ss.ss_store_sk,
        ss.ss_quantity,
        ss.ss_ext_sales_price,
        wr.wr_return_quantity,
        wr.wr_net_loss,
        CASE WHEN ss.ss_quantity > 10 THEN 'large' ELSE 'small' END AS qty_category,
        r.r_reason_desc
    FROM date_dim d
    JOIN (
        SELECT * FROM store_sales TABLESAMPLE BERNOULLI (10)
    ) ss ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN web_returns wr ON wr.wr_returned_date_sk = d.d_date_sk
    JOIN reason r ON wr.wr_reason_sk = r.r_reason_sk
    JOIN inventory inv ON inv.inv_date_sk = d.d_date_sk
    WHERE d.d_current_year = 'Y'
      AND d.d_month_seq BETWEEN 1200 AND 1300
      AND ss.ss_wholesale_cost > 20
      AND inv.inv_warehouse_sk IN (4, 12, 3)
      AND r.r_reason_id LIKE 'AAAAAAA%'
      AND wr.wr_return_amt_inc_tax > 100
      AND d.d_weekend = 'N'
),
agg1 AS (
    SELECT
        d_year,
        qty_category,
        COUNT(DISTINCT ss_item_sk) AS distinct_items_sold,
        SUM(ss_ext_sales_price) AS total_sales,
        SUM(wr_net_loss) AS total_loss,
        AVG(CASE WHEN qty_category = 'large' THEN ss_ext_sales_price END) AS avg_large_sales
    FROM base
    GROUP BY d_year, qty_category
)
SELECT
    d_year,
    qty_category,
    distinct_items_sold,
    total_sales,
    total_loss,
    avg_large_sales,
    (total_sales - total_loss) AS net_contribution
FROM agg1
WHERE total_sales > 5000
  AND distinct_items_sold >= 5
  AND avg_large_sales IS NOT NULL
UNION
SELECT
    d_year,
    qty_category,
    distinct_items_sold,
    total_sales,
    total_loss,
    avg_large_sales,
    (total_sales - total_loss) AS net_contribution
FROM agg1
WHERE (total_sales - total_loss) < 0
ORDER BY d_year DESC, qty_category
LIMIT 100

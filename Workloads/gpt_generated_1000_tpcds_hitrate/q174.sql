WITH store_part AS (
    SELECT
        'store' AS source,
        i.i_brand AS brand,
        ss.ss_ext_sales_price AS sales_amount,
        ss.ss_ticket_number
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    WHERE d.d_year = 2001
      AND EXISTS (
          SELECT 1
          FROM inventory inv
          WHERE inv.inv_item_sk = ss.ss_item_sk
            AND inv.inv_date_sk = ss.ss_sold_date_sk
            AND inv.inv_quantity_on_hand > 0
      )
),
catalog_part AS (
    SELECT
        'catalog' AS source,
        i.i_brand AS brand,
        cs.cs_ext_sales_price AS sales_amount,
        cs.cs_order_number
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    WHERE d.d_year = 2002
      AND cs.cs_ext_sales_price > 0
)
SELECT
    source,
    COUNT(DISTINCT brand) AS distinct_brand_count,
    SUM(DISTINCT sales_amount) AS distinct_sales_sum,
    SUM(sales_amount) AS total_sales,
    COUNT(*) AS transaction_count
FROM (
    SELECT * FROM store_part
    UNION ALL
    SELECT * FROM catalog_part
) u
GROUP BY source
ORDER BY total_sales DESC
LIMIT 100

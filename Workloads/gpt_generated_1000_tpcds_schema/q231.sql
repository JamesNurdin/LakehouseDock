WITH sales_item_agg AS (
    SELECT
        cs.cs_item_sk,
        i.i_brand,
        SUM(cs.cs_ext_sales_price) AS total_sales,
        SUM(cs.cs_net_profit) AS total_profit,
        COUNT(*) AS sales_cnt
    FROM catalog_sales cs
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    JOIN catalog_returns cr ON cr.cr_order_number = cs.cs_order_number
                              AND cr.cr_item_sk = cs.cs_item_sk
    JOIN inventory inv ON inv.inv_item_sk = i.i_item_sk
    WHERE cs.cs_sold_date_sk BETWEEN 2450800 AND 2451100               -- filter 1: date range
      AND i.i_manufact_id IN (460, 212)                               -- filter 2: specific manufacturers
      AND inv.inv_warehouse_sk = 10                                   -- filter 3: specific warehouse
    GROUP BY cs.cs_item_sk, i.i_brand
)
SELECT
    sia.cs_item_sk,
    sia.i_brand,
    sia.total_sales,
    sia.total_profit,
    sia.sales_cnt,
    (
        SELECT COUNT(*)
        FROM catalog_returns cr2
        WHERE cr2.cr_item_sk = sia.cs_item_sk
    ) AS return_count,
    CASE
        WHEN sia.total_sales > (
            SELECT MAX(cs_ext_sales_price)
            FROM catalog_sales
            WHERE cs_sold_date_sk = 2450941
        ) THEN 'Above Max'
        ELSE 'Below Max'
    END AS sales_vs_max
FROM sales_item_agg sia
WHERE sia.total_profit / NULLIF(sia.sales_cnt, 0) > 1000               -- filter 4: profit per sale
  AND sia.total_sales BETWEEN 5000 AND 20000                               -- filter 5: sales range
  AND sia.cs_item_sk NOT IN (SELECT cr3.cr_item_sk FROM catalog_returns cr3) -- filter 6: exclude items with returns
EXCEPT
SELECT
    cs.cs_item_sk,
    i.i_brand,
    CAST(0 AS decimal(7,2)) AS total_sales,
    CAST(0 AS decimal(7,2)) AS total_profit,
    CAST(0 AS bigint) AS sales_cnt,
    CAST(0 AS bigint) AS return_count,
    CAST('Excluded' AS varchar) AS sales_vs_max
FROM catalog_sales cs
JOIN item i ON cs.cs_item_sk = i.i_item_sk
WHERE cs.cs_sold_date_sk = 2450941
LIMIT 100

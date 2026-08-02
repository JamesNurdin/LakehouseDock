-- Goal: Compare total sales and returns by item brand and class, including subtotals, while retaining items without sales (using a RIGHT OUTER JOIN) and combine sales and returns via UNION ALL.
WITH sales AS (
    SELECT
        i.i_item_sk,
        i.i_brand,
        i.i_class,
        COALESCE(SUM(ss.ss_ext_sales_price), 0) AS sales_amount,
        CAST(0 AS decimal(7,2)) AS return_amount
    FROM store_sales ss
    RIGHT OUTER JOIN item i
        ON ss.ss_item_sk = i.i_item_sk
        AND ss.ss_sold_date_sk BETWEEN 2451150 AND 2451545
    LEFT JOIN promotion p
        ON ss.ss_promo_sk = p.p_promo_sk
        AND p.p_channel_catalog = 'N'
        AND p.p_channel_press = 'N'
    GROUP BY i.i_item_sk, i.i_brand, i.i_class
),
returns AS (
    SELECT
        i.i_item_sk,
        i.i_brand,
        i.i_class,
        CAST(0 AS decimal(7,2)) AS sales_amount,
        COALESCE(SUM(cr.cr_return_amt_inc_tax), 0) AS return_amount
    FROM catalog_returns cr
    JOIN item i
        ON cr.cr_item_sk = i.i_item_sk
    WHERE cr.cr_returned_date_sk BETWEEN 2451150 AND 2451545
    GROUP BY i.i_item_sk, i.i_brand, i.i_class
)
SELECT
    i_brand,
    i_class,
    SUM(sales_amount) AS total_sales,
    SUM(return_amount) AS total_returns,
    SUM(sales_amount) - SUM(return_amount) AS net_sales
FROM (
    SELECT i_brand, i_class, sales_amount, return_amount FROM sales
    UNION ALL
    SELECT i_brand, i_class, sales_amount, return_amount FROM returns
) AS combined
GROUP BY ROLLUP (i_brand, i_class)
ORDER BY i_brand, i_class
LIMIT 100

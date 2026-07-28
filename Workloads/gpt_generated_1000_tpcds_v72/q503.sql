WITH store_sales_agg AS (
    SELECT
        i.i_item_id,
        i.i_product_name,
        SUM(ss.ss_ext_sales_price) AS total_amount,
        'store' AS source
    FROM tpcds.store_sales ss
    JOIN tpcds.item i ON ss.ss_item_sk = i.i_item_sk
    WHERE ss.ss_sold_date_sk BETWEEN 2451880 AND 2452000
    GROUP BY i.i_item_id, i.i_product_name
    HAVING SUM(ss.ss_ext_sales_price) > 1000
),
web_returns_agg AS (
    SELECT
        i.i_item_id,
        i.i_product_name,
        SUM(wr.wr_return_amt_inc_tax) AS total_amount,
        'web' AS source
    FROM tpcds.web_returns wr
    JOIN tpcds.item i ON wr.wr_item_sk = i.i_item_sk
    WHERE wr.wr_returned_date_sk BETWEEN 2451880 AND 2452000
    GROUP BY i.i_item_id, i.i_product_name
    HAVING SUM(wr.wr_return_amt_inc_tax) > 500
)
SELECT
    i_item_id,
    i_product_name,
    total_amount,
    source
FROM store_sales_agg
UNION ALL
SELECT
    i_item_id,
    i_product_name,
    total_amount,
    source
FROM web_returns_agg
ORDER BY total_amount DESC
LIMIT 100

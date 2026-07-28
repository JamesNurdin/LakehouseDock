WITH high_returns AS (
    SELECT
        i.i_item_id,
        i.i_product_name,
        wp.wp_type,
        SUM(wr.wr_return_amt_inc_tax) AS total_return_amt_inc_tax
    FROM web_returns wr
    JOIN item i ON wr.wr_item_sk = i.i_item_sk
    JOIN web_page wp ON wr.wr_web_page_sk = wp.wp_web_page_sk
    WHERE wr.wr_return_amt_inc_tax > 1000
      AND i.i_wholesale_cost < 2
    GROUP BY i.i_item_id, i.i_product_name, wp.wp_type
),
low_returns AS (
    SELECT
        i.i_item_id,
        i.i_product_name,
        wp.wp_type,
        SUM(wr.wr_return_amt_inc_tax) AS total_return_amt_inc_tax
    FROM web_returns wr
    JOIN item i ON wr.wr_item_sk = i.i_item_sk
    JOIN web_page wp ON wr.wr_web_page_sk = wp.wp_web_page_sk
    WHERE wr.wr_return_amt_inc_tax < 200
      AND wp.wp_max_ad_count = 0
    GROUP BY i.i_item_id, i.i_product_name, wp.wp_type
)
SELECT DISTINCT
    item_id,
    product_name,
    page_type,
    total_return_amt_inc_tax
FROM (
    SELECT i_item_id AS item_id,
           i_product_name AS product_name,
           wp_type AS page_type,
           total_return_amt_inc_tax
    FROM high_returns
    UNION ALL
    SELECT i_item_id AS item_id,
           i_product_name AS product_name,
           wp_type AS page_type,
           total_return_amt_inc_tax
    FROM low_returns
) combined
ORDER BY total_return_amt_inc_tax DESC
LIMIT 100

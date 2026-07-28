WITH sales AS (
    SELECT DISTINCT
        i.i_item_id,
        i.i_item_desc,
        i.i_category,
        cs.cs_ext_sales_price AS total_amount,
        'sale' AS transaction_type,
        ca.ca_state
    FROM catalog_sales cs
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    JOIN household_demographics hd ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
    JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
    JOIN customer_address ca ON cs.cs_bill_addr_sk = ca.ca_address_sk
    WHERE i.i_current_price > (SELECT avg(i2.i_current_price) FROM item i2)
      AND w.w_state = 'CA'
      AND EXISTS (
          SELECT 1 FROM warehouse w2
          WHERE w2.w_state = ca.ca_state
            AND w2.w_warehouse_sq_ft > 200000
      )
),
returns AS (
    SELECT DISTINCT
        i.i_item_id,
        i.i_item_desc,
        i.i_category,
        wr.wr_return_amt AS total_amount,
        'return' AS transaction_type,
        ca.ca_state
    FROM web_returns wr
    JOIN item i ON wr.wr_item_sk = i.i_item_sk
    JOIN household_demographics hd ON wr.wr_refunded_hdemo_sk = hd.hd_demo_sk
    JOIN customer_address ca ON wr.wr_refunded_addr_sk = ca.ca_address_sk
    JOIN web_page wp ON wr.wr_web_page_sk = wp.wp_web_page_sk
    WHERE wp.wp_type = 'product'
      AND EXISTS (
          SELECT 1 FROM warehouse w3
          WHERE w3.w_state = ca.ca_state
            AND w3.w_warehouse_sq_ft > 200000
      )
)
SELECT
    item_id,
    item_desc,
    category,
    total_amount,
    transaction_type
FROM (
    SELECT
        i_item_id AS item_id,
        i_item_desc AS item_desc,
        i_category AS category,
        total_amount,
        transaction_type
    FROM sales
    UNION ALL
    SELECT
        i_item_id,
        i_item_desc,
        i_category,
        total_amount,
        transaction_type
    FROM returns
) AS combined
ORDER BY total_amount DESC
LIMIT 100

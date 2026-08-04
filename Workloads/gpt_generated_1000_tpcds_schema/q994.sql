WITH sampled_sales AS (
        SELECT *
        FROM catalog_sales
        TABLESAMPLE BERNOULLI (10)
    ),
    max_item_price AS (
        SELECT MAX(i_current_price) AS max_price
        FROM item
    )
SELECT
    cc.cc_name,
    w.w_city,
    i.i_brand,
    SUM(ss.cs_net_paid) AS total_net_paid,
    SUM(cr.cr_return_amount) AS total_return_amount,
    COUNT(DISTINCT ss.cs_order_number) AS order_count,
    AVG(wr.wr_fee) AS avg_return_fee,
    ROW_NUMBER() OVER (PARTITION BY cc.cc_name ORDER BY SUM(ss.cs_net_paid) DESC) AS rn
FROM sampled_sales ss
FULL OUTER JOIN catalog_returns cr
    ON ss.cs_order_number = cr.cr_order_number
JOIN call_center cc
    ON ss.cs_call_center_sk = cc.cc_call_center_sk
JOIN catalog_page cp
    ON ss.cs_catalog_page_sk = cp.cp_catalog_page_sk
JOIN warehouse w
    ON ss.cs_warehouse_sk = w.w_warehouse_sk
JOIN item i
    ON ss.cs_item_sk = i.i_item_sk
JOIN customer c
    ON ss.cs_bill_customer_sk = c.c_customer_sk
LEFT JOIN web_returns wr
    ON wr.wr_item_sk = i.i_item_sk
    AND wr.wr_refunded_customer_sk = c.c_customer_sk
WHERE
    cc.cc_zip = '98048'
    AND w.w_county = 'Bronx County'
    AND ss.cs_wholesale_cost < 40
    AND cp.cp_start_date_sk = 2451115
    AND cr.cr_return_quantity > 1
    AND wr.wr_fee > 50
    AND i.i_current_price < (SELECT max_price FROM max_item_price)
    AND NOT EXISTS (
        SELECT 1
        FROM web_returns wr2
        WHERE wr2.wr_returning_customer_sk = c.c_customer_sk
          AND wr2.wr_net_loss > 100
    )
GROUP BY
    cc.cc_name,
    w.w_city,
    i.i_brand
ORDER BY total_net_paid DESC
OFFSET 0 LIMIT 100

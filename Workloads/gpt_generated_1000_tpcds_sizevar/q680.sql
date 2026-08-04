WITH sampled_sales AS (
    SELECT ss.ss_sold_date_sk,
           ss.ss_item_sk,
           ss.ss_customer_sk,
           ss.ss_ticket_number,
           ss.ss_ext_sales_price
    FROM store_sales ss
    TABLESAMPLE BERNOULLI (10)
)
SELECT item_id
FROM (
    SELECT i.i_item_id AS item_id,
           SUM(ss.ss_ext_sales_price) AS total_sales,
           ss.ss_sold_date_sk
    FROM sampled_sales ss
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    GROUP BY CUBE(i.i_item_id, ss.ss_sold_date_sk)
    HAVING SUM(ss.ss_ext_sales_price) > 1000
) a
INTERSECT
SELECT item_id
FROM (
    SELECT i.i_item_id AS item_id
    FROM catalog_returns cr
    JOIN item i ON cr.cr_item_sk = i.i_item_sk
    WHERE cr.cr_return_amount > 150
      AND NOT EXISTS (
          SELECT 1
          FROM catalog_sales cs
          WHERE cs.cs_order_number = cr.cr_order_number
            AND cs.cs_net_paid > 500
      )
) b
EXCEPT
SELECT item_id
FROM (
    SELECT i.i_item_id AS item_id
    FROM store_returns sr
    JOIN item i ON sr.sr_item_sk = i.i_item_sk
    JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
    WHERE r.r_reason_desc = 'Customer Not Satisfied'
) c
LIMIT 100

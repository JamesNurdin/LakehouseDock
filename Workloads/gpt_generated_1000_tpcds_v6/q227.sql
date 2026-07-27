WITH catalog_part AS (
    SELECT
        c.c_customer_id,
        d.d_year,
        SUM(cr.cr_return_amount) AS total_return_amount,
        COUNT(DISTINCT cr.cr_item_sk) AS distinct_items_returned,
        'catalog' AS channel,
        (SELECT AVG(cr2.cr_return_amount)
         FROM catalog_returns cr2
         JOIN date_dim d2 ON cr2.cr_returned_date_sk = d2.d_date_sk
         WHERE d2.d_year = 2020) AS avg_return_amount
    FROM catalog_returns cr
    JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
    JOIN customer c ON cr.cr_refunded_customer_sk = c.c_customer_sk
    WHERE d.d_year = 2020
      AND EXISTS (
          SELECT 1
          FROM catalog_sales cs
          WHERE cs.cs_order_number = cr.cr_order_number
            AND cs.cs_item_sk = cr.cr_item_sk
      )
    GROUP BY c.c_customer_id, d.d_year
    HAVING SUM(cr.cr_return_amount) > 1000
),
web_part AS (
    SELECT
        c.c_customer_id,
        d.d_year,
        SUM(wr.wr_return_amt) AS total_return_amount,
        COUNT(DISTINCT wr.wr_item_sk) AS distinct_items_returned,
        'web' AS channel,
        (SELECT AVG(wr2.wr_return_amt)
         FROM web_returns wr2
         JOIN date_dim d2 ON wr2.wr_returned_date_sk = d2.d_date_sk
         WHERE d2.d_year = 2020) AS avg_return_amount
    FROM web_returns wr
    JOIN date_dim d ON wr.wr_returned_date_sk = d.d_date_sk
    JOIN customer c ON wr.wr_refunded_customer_sk = c.c_customer_sk
    WHERE d.d_year = 2020
      AND EXISTS (
          SELECT 1
          FROM web_sales ws
          WHERE ws.ws_order_number = wr.wr_order_number
            AND ws.ws_item_sk = wr.wr_item_sk
      )
    GROUP BY c.c_customer_id, d.d_year
    HAVING SUM(wr.wr_return_amt) > 1000
)
SELECT DISTINCT
    cp.c_customer_id,
    cp.d_year,
    cp.channel,
    cp.total_return_amount,
    cp.distinct_items_returned,
    cp.avg_return_amount
FROM catalog_part cp
UNION ALL
SELECT DISTINCT
    wp.c_customer_id,
    wp.d_year,
    wp.channel,
    wp.total_return_amount,
    wp.distinct_items_returned,
    wp.avg_return_amount
FROM web_part wp
ORDER BY total_return_amount DESC
LIMIT 100

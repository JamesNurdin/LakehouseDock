WITH combined_sales AS (
    SELECT i.i_item_id AS item_id,
           d.d_year AS year,
           d.d_month_seq AS month_seq,
           SUM(ss.ss_net_paid) AS sales_amount,
           'store' AS channel
    FROM store_sales ss
    INNER JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    INNER JOIN item i ON ss.ss_item_sk = i.i_item_sk
    WHERE d.d_year = 2001
      AND ss.ss_quantity > 0
    GROUP BY i.i_item_id, d.d_year, d.d_month_seq
    UNION ALL
    SELECT i.i_item_id AS item_id,
           d.d_year AS year,
           d.d_month_seq AS month_seq,
           SUM(ws.ws_net_paid) AS sales_amount,
           'web' AS channel
    FROM web_sales ws
    INNER JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    INNER JOIN item i ON ws.ws_item_sk = i.i_item_sk
    WHERE d.d_year = 2001
      AND ws.ws_quantity > 0
    GROUP BY i.i_item_id, d.d_year, d.d_month_seq
)
SELECT channel,
       year,
       month_seq,
       item_id,
       sales_amount,
       SUM(sales_amount) OVER (PARTITION BY channel ORDER BY year, month_seq) AS running_total
FROM combined_sales
ORDER BY channel, year, month_seq, sales_amount DESC
LIMIT 100

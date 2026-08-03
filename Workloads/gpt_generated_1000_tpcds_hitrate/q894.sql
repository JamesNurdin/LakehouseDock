WITH joined_data AS (
   SELECT
       ss.ss_store_sk,
       ss.ss_sold_date_sk,
       t.t_hour,
       ss.ss_ext_sales_price,
       ss.ss_net_paid_inc_tax,
       sr.sr_return_quantity,
       sr.sr_return_amt,
       sr.sr_store_credit,
       wr.wr_return_quantity,
       wr.wr_return_amt,
       wp.wp_type,
       CASE
           WHEN sr.sr_return_quantity IS NOT NULL AND sr.sr_return_quantity > 0 THEN 'Returned'
           ELSE 'Sold'
       END AS sale_status
   FROM store_sales ss
   LEFT JOIN store_returns sr
       ON ss.ss_item_sk = sr.sr_item_sk
      AND ss.ss_ticket_number = sr.sr_ticket_number
   JOIN time_dim t
       ON ss.ss_sold_time_sk = t.t_time_sk
   LEFT JOIN web_returns wr
       ON wr.wr_returned_time_sk = t.t_time_sk
   LEFT JOIN web_page wp
       ON wr.wr_web_page_sk = wp.wp_web_page_sk
   WHERE ss.ss_list_price > 100
     AND sr.sr_store_credit < 1000
     AND wp.wp_rec_start_date >= DATE '2000-01-01'
     AND t.t_hour BETWEEN 9 AND 17
),
aggregated AS (
   SELECT
       ss_store_sk,
       t_hour,
       COUNT(DISTINCT ss_sold_date_sk) AS distinct_sales_days,
       SUM(ss_ext_sales_price) AS total_sales_price,
       AVG(ss_net_paid_inc_tax) AS avg_net_paid_inc_tax,
       SUM(COALESCE(sr_return_amt, 0)) AS total_return_amount,
       SUM(COALESCE(wr_return_amt, 0)) AS total_web_return_amount,
       MIN(sr_store_credit) AS min_store_credit,
       MAX(wr_return_quantity) AS max_web_return_qty,
       SUM(CASE WHEN sale_status = 'Returned' THEN 1 ELSE 0 END) AS returned_transactions
   FROM joined_data
   GROUP BY ss_store_sk, t_hour
   HAVING SUM(ss_ext_sales_price) > 0
),
ranked AS (
   SELECT
       *,
       ROW_NUMBER() OVER (PARTITION BY ss_store_sk ORDER BY total_sales_price DESC) AS rn
   FROM aggregated
)
SELECT
   ss_store_sk,
   t_hour,
   distinct_sales_days,
   total_sales_price,
   avg_net_paid_inc_tax,
   total_return_amount,
   total_web_return_amount,
   min_store_credit,
   max_web_return_qty,
   returned_transactions
FROM ranked
WHERE rn <= 5
ORDER BY ss_store_sk, t_hour
LIMIT 100

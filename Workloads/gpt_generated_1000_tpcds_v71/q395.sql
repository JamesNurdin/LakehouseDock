WITH base AS (
   SELECT
     i.i_category,
     ca.ca_state,
     td.t_hour,
     ss.ss_net_paid,
     sr.sr_net_loss,
     wr.wr_net_loss
   FROM store_sales ss
   JOIN time_dim td
     ON ss.ss_sold_time_sk = td.t_time_sk
   JOIN item i
     ON ss.ss_item_sk = i.i_item_sk
   JOIN customer_address ca
     ON ss.ss_addr_sk = ca.ca_address_sk
   LEFT JOIN store_returns sr
     ON ss.ss_ticket_number = sr.sr_ticket_number
    AND ss.ss_item_sk = sr.sr_item_sk
   LEFT JOIN web_returns wr
     ON td.t_time_sk = wr.wr_returned_time_sk
    AND i.i_item_sk = wr.wr_item_sk
   WHERE i.i_brand = 'BrandX'
     AND ca.ca_state = 'CA'
     AND td.t_hour BETWEEN 9 AND 17
),
agg AS (
   SELECT
     i_category,
     ca_state,
     t_hour,
     SUM(ss_net_paid) AS total_sales,
     SUM(sr_net_loss) AS total_store_return_loss,
     SUM(wr_net_loss) AS total_web_return_loss
   FROM base
   GROUP BY ROLLUP(i_category, ca_state, t_hour)
)
SELECT
   i_category,
   ca_state,
   t_hour,
   total_sales,
   total_store_return_loss,
   total_web_return_loss,
   ROW_NUMBER() OVER (ORDER BY total_sales DESC) AS sales_rank
FROM agg
WHERE total_sales IS NOT NULL
ORDER BY sales_rank
LIMIT 100

WITH sales_chain AS (
   SELECT 
       cd.cd_demo_sk,
       cd.cd_gender,
       cd.cd_credit_rating,
       i.i_item_sk,
       i.i_product_name,
       s.s_store_sk,
       s.s_store_name,
       ss.ss_ticket_number,
       ss.ss_quantity,
       ss.ss_sales_price,
       sr.sr_return_quantity,
       sr.sr_return_amt,
       sr.sr_fee,
       sr.sr_return_ship_cost,
       sr.sr_net_loss
   FROM tpcds.customer_demographics cd
   JOIN tpcds.store_sales ss
       ON ss.ss_cdemo_sk = cd.cd_demo_sk
   JOIN tpcds.item i
       ON ss.ss_item_sk = i.i_item_sk
   JOIN tpcds.store s
       ON ss.ss_store_sk = s.s_store_sk
   LEFT JOIN tpcds.store_returns sr
       ON sr.sr_item_sk = ss.ss_item_sk
      AND sr.sr_ticket_number = ss.ss_ticket_number
   WHERE cd.cd_credit_rating IN ('Good', 'High Risk', 'Low Risk')
     AND i.i_current_price > 10
     AND s.s_state = 'CA'
     AND ss.ss_quantity > 0
     AND ss.ss_sales_price > 0
     AND cd.cd_dep_count BETWEEN 0 AND 4
),
web_chain AS (
   SELECT 
       cd.cd_demo_sk,
       cd.cd_gender,
       cd.cd_credit_rating,
       i.i_item_sk,
       i.i_product_name,
       wr.wr_order_number,
       wr.wr_return_quantity,
       wr.wr_return_amt,
       wr.wr_fee,
       wr.wr_net_loss
   FROM tpcds.customer_demographics cd
   JOIN tpcds.web_returns wr
       ON wr.wr_refunded_cdemo_sk = cd.cd_demo_sk
   JOIN tpcds.item i
       ON wr.wr_item_sk = i.i_item_sk
   WHERE cd.cd_credit_rating IN ('Good', 'High Risk')
     AND i.i_current_price BETWEEN 5 AND 50
     AND wr.wr_return_quantity > 0
     AND wr.wr_return_amt > 0
     AND cd.cd_dep_employed_count <= 2
),
combined AS (
   SELECT 
       COALESCE(sc.i_item_sk, wc.i_item_sk) AS item_sk,
       COALESCE(sc.i_product_name, wc.i_product_name) AS product_name,
       sc.ss_quantity,
       sc.ss_sales_price,
       sc.sr_return_quantity,
       wc.wr_return_quantity,
       sc.sr_fee,
       wc.wr_fee,
       sc.sr_net_loss,
       wc.wr_net_loss,
       sc.sr_return_amt,
       wc.wr_return_amt
   FROM sales_chain sc
   FULL OUTER JOIN web_chain wc
       ON sc.i_item_sk = wc.i_item_sk
),
unnested_fees AS (
   SELECT 
       item_sk,
       product_name,
       fee
   FROM combined
   CROSS JOIN UNNEST(array[COALESCE(sr_fee, 0), COALESCE(wr_fee, 0)]) AS t(fee)
),
agg AS (
   SELECT 
       c.item_sk,
       c.product_name,
       SUM(COALESCE(c.ss_quantity, 0)) AS total_sold_quantity,
       SUM(COALESCE(c.ss_sales_price, 0)) AS total_sales_amount,
       SUM(COALESCE(c.sr_return_quantity, 0) + COALESCE(c.wr_return_quantity, 0)) AS total_return_quantity,
       SUM(COALESCE(c.sr_return_amt, 0) + COALESCE(c.wr_return_amt, 0)) AS total_return_amount,
       SUM(COALESCE(c.sr_net_loss, 0) + COALESCE(c.wr_net_loss, 0)) AS total_net_loss,
       ROW_NUMBER() OVER (ORDER BY SUM(COALESCE(c.ss_sales_price, 0)) DESC) AS sales_rank
   FROM combined c
   GROUP BY c.item_sk, c.product_name
   HAVING SUM(COALESCE(c.ss_sales_price, 0)) > 1000
)
SELECT 
   a.item_sk,
   a.product_name,
   a.total_sold_quantity,
   a.total_sales_amount,
   a.total_return_quantity,
   a.total_return_amount,
   a.total_net_loss,
   a.sales_rank,
   CASE 
       WHEN a.total_net_loss > 0 THEN 'LOSS'
       WHEN a.total_net_loss < 0 THEN 'PROFIT'
       ELSE 'BREAK-EVEN'
   END AS profit_status,
   f.avg_fee_per_item
FROM agg a
LEFT JOIN (
   SELECT 
       item_sk,
       AVG(fee) AS avg_fee_per_item
   FROM unnested_fees
   GROUP BY item_sk
) f ON a.item_sk = f.item_sk
ORDER BY a.sales_rank
LIMIT 100

SELECT *
FROM (
   SELECT
       cs.cs_sold_date_sk,
       SUM(cs.cs_net_paid) AS total_sales,
       SUM(cs.cs_ext_discount_amt) AS total_discount,
       SUM(cs.cs_net_profit) AS total_profit,
       SUM(CASE WHEN wr.wr_return_quantity IS NOT NULL THEN wr.wr_return_quantity ELSE 0 END) AS total_return_qty,
       SUM(CASE WHEN wr.wr_return_quantity IS NOT NULL THEN wr.wr_return_amt_inc_tax ELSE 0 END) AS total_return_amount,
       (SUM(cs.cs_net_paid) - SUM(CASE WHEN wr.wr_return_quantity IS NOT NULL THEN wr.wr_return_amt_inc_tax ELSE 0 END)) AS net_sales_after_returns,
       ROUND((SUM(CASE WHEN wr.wr_return_quantity IS NOT NULL THEN wr.wr_return_amt_inc_tax ELSE 0 END) / NULLIF(SUM(cs.cs_net_paid), 0)) * 100, 2) AS return_rate_pct,
       RANK() OVER (ORDER BY (SUM(cs.cs_net_paid) - SUM(CASE WHEN wr.wr_return_quantity IS NOT NULL THEN wr.wr_return_amt_inc_tax ELSE 0 END)) DESC) AS sales_rank
   FROM catalog_sales cs
   LEFT JOIN web_returns wr
        ON cs.cs_order_number = wr.wr_order_number
        AND cs.cs_item_sk = wr.wr_item_sk
   WHERE cs.cs_sold_date_sk BETWEEN 2450800 AND 2450900
     AND cs.cs_net_profit > 0
   GROUP BY cs.cs_sold_date_sk
   HAVING SUM(cs.cs_net_paid) > 10000
) t
ORDER BY t.sales_rank
LIMIT 50

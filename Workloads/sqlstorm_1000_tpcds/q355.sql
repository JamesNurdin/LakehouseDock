WITH store_sales_agg AS (
    SELECT ss.ss_sold_date_sk AS date_sk,
           ss.ss_store_sk AS store_sk,
           i.i_category AS category,
           SUM(ss.ss_net_profit) AS net_profit,
           SUM(ss.ss_ext_sales_price) AS sales,
           COUNT(*) AS order_cnt
    FROM store_sales ss
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    GROUP BY ss.ss_sold_date_sk, ss.ss_store_sk, i.i_category
),
store_returns_agg AS (
    SELECT sr.sr_returned_date_sk AS date_sk,
           sr.sr_store_sk AS store_sk,
           i.i_category AS category,
           SUM(sr.sr_net_loss) AS net_loss,
           SUM(sr.sr_return_amt) AS return_amt,
           COUNT(*) AS return_cnt
    FROM store_returns sr
    JOIN item i ON sr.sr_item_sk = i.i_item_sk
    GROUP BY sr.sr_returned_date_sk, sr.sr_store_sk, i.i_category
),
combined AS (
    SELECT COALESCE(ssa.date_sk, sra.date_sk) AS date_sk,
           COALESCE(ssa.store_sk, sra.store_sk) AS store_sk,
           COALESCE(ssa.category, sra.category) AS category,
           COALESCE(ssa.net_profit, 0) - COALESCE(sra.net_loss, 0) AS net_profit_adj,
           COALESCE(ssa.sales, 0) - COALESCE(sra.return_amt, 0) AS net_sales_adj,
           COALESCE(ssa.order_cnt, 0) - COALESCE(sra.return_cnt, 0) AS net_orders_adj
    FROM store_sales_agg ssa
    FULL OUTER JOIN store_returns_agg sra
      ON ssa.date_sk = sra.date_sk
     AND ssa.store_sk = sra.store_sk
     AND ssa.category = sra.category
)
SELECT d.d_year,
       s.s_store_name,
       c.category,
       c.net_profit_adj,
       c.net_sales_adj,
       c.net_orders_adj
FROM combined c
JOIN date_dim d ON c.date_sk = d.d_date_sk
JOIN store s ON c.store_sk = s.s_store_sk
WHERE d.d_year BETWEEN 1999 AND 2001
ORDER BY c.net_profit_adj DESC
LIMIT 100

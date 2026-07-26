WITH sales_item AS (
    SELECT cs.cs_item_sk AS item_sk,
           SUM(cs.cs_net_profit) AS sales_net_profit,
           SUM(cs.cs_ext_sales_price) AS sales_ext_price,
           COUNT(*) AS sales_cnt
    FROM catalog_sales cs
    GROUP BY cs.cs_item_sk
),
returns_item AS (
    SELECT sr.sr_item_sk AS item_sk,
           SUM(sr.sr_net_loss) AS return_net_loss,
           SUM(sr.sr_return_amt_inc_tax) AS return_ext_amount,
           COUNT(*) AS returns_cnt
    FROM store_returns sr
    GROUP BY sr.sr_item_sk
),
item_store_counts AS (
    SELECT item_sk,
           s_store_name,
           store_return_cnt,
           ROW_NUMBER() OVER (PARTITION BY item_sk ORDER BY store_return_cnt DESC) AS rn
    FROM (
        SELECT sr.sr_item_sk AS item_sk,
               s.s_store_name,
               COUNT(*) AS store_return_cnt
        FROM store_returns sr
        JOIN store s ON sr.sr_store_sk = s.s_store_sk
        GROUP BY sr.sr_item_sk, s.s_store_name
    ) sub
)
SELECT i.item_sk,
       COALESCE(si.sales_net_profit,0) AS total_sales_profit,
       COALESCE(ri.return_net_loss,0) AS total_return_loss,
       (COALESCE(si.sales_net_profit,0) - COALESCE(ri.return_net_loss,0)) AS net_balance,
       COALESCE(ist.s_store_name,'Unknown') AS top_return_store,
       CASE
           WHEN (COALESCE(si.sales_net_profit,0) - COALESCE(ri.return_net_loss,0)) >= 20000 THEN 'Very Profitable'
           WHEN (COALESCE(si.sales_net_profit,0) - COALESCE(ri.return_net_loss,0)) >= 10000 THEN 'Profitable'
           WHEN (COALESCE(si.sales_net_profit,0) - COALESCE(ri.return_net_loss,0)) >= 0 THEN 'Break-even'
           ELSE 'Loss'
       END AS profitability_category,
       RANK() OVER (ORDER BY (COALESCE(si.sales_net_profit,0) - COALESCE(ri.return_net_loss,0)) DESC) AS profit_rank
FROM (
    SELECT cs.cs_item_sk AS item_sk FROM catalog_sales cs
    UNION
    SELECT sr.sr_item_sk AS item_sk FROM store_returns sr
) i
LEFT JOIN sales_item si ON si.item_sk = i.item_sk
LEFT JOIN returns_item ri ON ri.item_sk = i.item_sk
LEFT JOIN item_store_counts ist ON ist.item_sk = i.item_sk AND ist.rn = 1
ORDER BY profit_rank
LIMIT 100

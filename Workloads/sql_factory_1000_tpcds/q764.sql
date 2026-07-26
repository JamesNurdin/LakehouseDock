WITH sales_union AS (
   SELECT cs_item_sk AS item_sk,
          cs_net_profit AS net_profit,
          cs_ext_discount_amt AS discount,
          'catalog' AS source
   FROM catalog_sales
   UNION ALL
   SELECT ws_item_sk AS item_sk,
          ws_net_profit AS net_profit,
          ws_ext_discount_amt AS discount,
          'web' AS source
   FROM web_sales
),
returns_agg AS (
   SELECT sr_item_sk AS item_sk,
          SUM(sr_net_loss) AS total_loss,
          SUM(sr_return_amt) AS total_return_amt,
          COUNT(*) AS return_cnt
   FROM store_returns
   GROUP BY sr_item_sk
),
item_agg AS (
   SELECT
      s.item_sk,
      SUM(s.net_profit) AS total_profit,
      SUM(s.discount) AS total_discount,
      COUNT(*) AS sales_cnt,
      COALESCE(r.total_loss, 0) AS total_loss,
      COALESCE(r.total_return_amt, 0) AS total_return_amt,
      COALESCE(r.return_cnt, 0) AS return_cnt
   FROM sales_union s
   LEFT JOIN returns_agg r ON s.item_sk = r.item_sk
   GROUP BY s.item_sk, r.total_loss, r.total_return_amt, r.return_cnt
)
SELECT
   item_sk,
   total_profit,
   total_loss,
   total_profit - total_loss AS net_contribution,
   CASE
      WHEN total_profit - total_loss > 5000 THEN 'High'
      WHEN total_profit - total_loss BETWEEN 1000 AND 5000 THEN 'Medium'
      ELSE 'Low'
   END AS contribution_category,
   DENSE_RANK() OVER (ORDER BY total_profit - total_loss DESC) AS profit_rank
FROM item_agg
ORDER BY net_contribution DESC
LIMIT 10

WITH promo_sales AS (
  SELECT cs_promo_sk AS promo_sk,
         cs_item_sk AS item_sk,
         cs_net_profit AS net_profit,
         cs_ext_discount_amt AS discount_amt,
         cs_sold_date_sk AS date_sk,
         'catalog' AS channel
  FROM catalog_sales
  UNION ALL
  SELECT ws_promo_sk AS promo_sk,
         ws_item_sk AS item_sk,
         ws_net_profit AS net_profit,
         ws_ext_discount_amt AS discount_amt,
         ws_sold_date_sk AS date_sk,
         'web' AS channel
  FROM web_sales
),
promo_agg AS (
  SELECT COALESCE(p.promo_sk, 0) AS promo_id,
         SUM(p.net_profit) AS total_net_profit,
         SUM(p.discount_amt) AS total_discount,
         CASE WHEN SUM(p.discount_amt) = 0 THEN 0 ELSE SUM(p.net_profit) / SUM(p.discount_amt) END AS profit_per_discount,
         COUNT(*) AS transaction_count,
         SUM(CASE WHEN p.channel = 'catalog' THEN 1 ELSE 0 END) AS catalog_txn,
         SUM(CASE WHEN p.channel = 'web' THEN 1 ELSE 0 END) AS web_txn,
         AVG(i.i_current_price) AS avg_item_price
  FROM promo_sales p
  JOIN date_dim d ON d.d_date_sk = p.date_sk
  JOIN item i ON i.i_item_sk = p.item_sk
  WHERE d.d_year BETWEEN 2000 AND 2002
  GROUP BY COALESCE(p.promo_sk, 0)
),
ranked_promos AS (
  SELECT promo_id,
         total_net_profit,
         total_discount,
         profit_per_discount,
         transaction_count,
         catalog_txn,
         web_txn,
         avg_item_price,
         RANK() OVER (ORDER BY profit_per_discount DESC) AS profit_per_discount_rank,
         DENSE_RANK() OVER (ORDER BY transaction_count DESC) AS txn_count_rank
  FROM promo_agg
)
SELECT rp.promo_id,
       rp.total_net_profit,
       rp.total_discount,
       rp.profit_per_discount,
       rp.transaction_count,
       rp.catalog_txn,
       rp.web_txn,
       rp.avg_item_price,
       rp.profit_per_discount_rank,
       rp.txn_count_rank,
       CASE WHEN rp.promo_id = 0 THEN 'No Promo' ELSE 'Promo' END AS promo_type
FROM ranked_promos rp
WHERE rp.profit_per_discount_rank <= 10
ORDER BY rp.profit_per_discount_rank

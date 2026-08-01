WITH
  agg_store AS (
    SELECT
      s.ss_promo_sk AS promo_sk,
      SUM(s.ss_net_profit) AS net_profit,
      COUNT(*) AS txn_cnt,
      AVG(s.ss_list_price) AS avg_list_price
    FROM store_sales s
    JOIN promotion p ON s.ss_promo_sk = p.p_promo_sk
    WHERE s.ss_list_price > 30
      AND s.ss_net_profit < 0
      AND p.p_channel_catalog = 'N'
      AND p.p_response_target = 1
    GROUP BY s.ss_promo_sk
  ),
  agg_catalog AS (
    SELECT
      c.cs_promo_sk AS promo_sk,
      SUM(c.cs_net_profit) AS net_profit,
      COUNT(*) AS txn_cnt,
      AVG(c.cs_list_price) AS avg_list_price
    FROM catalog_sales c
    JOIN promotion p ON c.cs_promo_sk = p.p_promo_sk
    WHERE c.cs_ext_ship_cost > 500
      AND c.cs_ship_customer_sk > 5000000
      AND p.p_channel_catalog = 'N'
      AND p.p_response_target = 1
    GROUP BY c.cs_promo_sk
  ),
  union_agg AS (
    SELECT promo_sk, net_profit, txn_cnt, avg_list_price FROM agg_store
    UNION
    SELECT promo_sk, net_profit, txn_cnt, avg_list_price FROM agg_catalog
  ),
  all_promos AS (
    SELECT p.p_promo_sk AS promo_sk FROM promotion p
  ),
  combined AS (
    SELECT ua.promo_sk, ua.net_profit, ua.txn_cnt, ua.avg_list_price
    FROM union_agg ua
    UNION
    SELECT ap.promo_sk, NULL AS net_profit, NULL AS txn_cnt, NULL AS avg_list_price
    FROM all_promos ap
    EXCEPT
    SELECT ua.promo_sk, ua.net_profit, ua.txn_cnt, ua.avg_list_price
    FROM union_agg ua
    WHERE ua.net_profit < -5000
  ),
  final AS (
    SELECT
      c.promo_sk,
      c.net_profit,
      c.txn_cnt,
      c.avg_list_price,
      p.p_promo_name,
      p.p_channel_catalog,
      RANK() OVER (PARTITION BY p.p_channel_catalog ORDER BY c.net_profit DESC) AS profit_rank
    FROM combined c
    FULL OUTER JOIN promotion p ON c.promo_sk = p.p_promo_sk
    WHERE NOT EXISTS (
      SELECT 1 FROM store_sales s
      WHERE s.ss_promo_sk = c.promo_sk
        AND s.ss_quantity > 100
    )
  )
SELECT
  promo_sk,
  net_profit,
  txn_cnt,
  avg_list_price,
  p_promo_name,
  p_channel_catalog,
  profit_rank
FROM final
WHERE profit_rank IS NOT NULL
ORDER BY profit_rank ASC, net_profit DESC
LIMIT 100

WITH cat_agg AS (
   SELECT
      p.p_promo_id,
      sm.sm_type,
      sm.sm_contract,
      SUM(cs.cs_net_profit) AS cat_net_profit,
      COUNT(*) AS cat_sales_cnt
   FROM catalog_sales cs
   JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
   JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
   WHERE
      sm.sm_type IN ('OVERNIGHT', 'EXPRESS')
      AND sm.sm_contract <> 'HVDFCcQ'
      AND p.p_channel_radio = 'N'
      AND p.p_channel_press = 'N'
      AND cs.cs_quantity > 1
   GROUP BY p.p_promo_id, sm.sm_type, sm.sm_contract
   HAVING SUM(cs.cs_net_profit) > 1000
),
web_agg AS (
   SELECT
      p.p_promo_id,
      sm.sm_type,
      sm.sm_contract,
      SUM(ws.ws_net_profit) AS web_net_profit,
      COUNT(*) AS web_sales_cnt
   FROM web_sales ws
   JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
   JOIN ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
   WHERE
      sm.sm_type IN ('OVERNIGHT', 'EXPRESS')
      AND sm.sm_contract <> 'HVDFCcQ'
      AND p.p_channel_radio = 'N'
      AND p.p_channel_press = 'N'
      AND ws.ws_ext_ship_cost > 500
   GROUP BY p.p_promo_id, sm.sm_type, sm.sm_contract
   HAVING SUM(ws.ws_net_profit) > 800
)
SELECT
   ca.p_promo_id,
   ca.sm_type,
   ca.sm_contract,
   ca.cat_net_profit,
   wa.web_net_profit,
   (ca.cat_net_profit + wa.web_net_profit) AS total_net_profit,
   ROW_NUMBER() OVER (PARTITION BY ca.sm_type ORDER BY (ca.cat_net_profit + wa.web_net_profit) DESC) AS rn_type,
   RANK() OVER (ORDER BY (ca.cat_net_profit + wa.web_net_profit) DESC) AS overall_rank,
   CASE
      WHEN (ca.cat_net_profit + wa.web_net_profit) > 5000 THEN 'HIGH'
      WHEN (ca.cat_net_profit + wa.web_net_profit) BETWEEN 2000 AND 5000 THEN 'MEDIUM'
      ELSE 'LOW'
   END AS profit_category
FROM cat_agg ca
JOIN web_agg wa
  ON ca.p_promo_id = wa.p_promo_id
 AND ca.sm_type = wa.sm_type
 AND ca.sm_contract = wa.sm_contract
ORDER BY total_net_profit DESC
LIMIT 100

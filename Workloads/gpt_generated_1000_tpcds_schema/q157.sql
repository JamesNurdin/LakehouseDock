WITH catalog_part AS (
  SELECT
    concat(p.p_promo_name, ' - ', sm.sm_carrier) AS label,
    cs.cs_net_profit AS net_profit
  FROM catalog_sales cs
  JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
  JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
  JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
  WHERE regexp_like(p.p_promo_name, '^[A-Z]{3}[0-9]{2}$')
    AND sm.sm_carrier LIKE 'F%'
),
store_part AS (
  SELECT
    concat(p.p_promo_name, ' - ', ca.ca_city) AS label,
    ss.ss_net_profit AS net_profit
  FROM store_sales ss
  JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
  JOIN customer_address ca ON ss.ss_addr_sk = ca.ca_address_sk
  WHERE regexp_like(p.p_promo_name, '^[A-Z]{3}[0-9]{2}$')
    AND ca.ca_city LIKE 'A%'
),
combined AS (
  SELECT * FROM catalog_part
  UNION ALL
  SELECT * FROM store_part
),
agg AS (
  SELECT
    label,
    sum(net_profit) AS total_profit,
    count(*) AS sales_cnt
  FROM combined
  GROUP BY label
)
SELECT
  label,
  total_profit,
  sales_cnt,
  sum(total_profit) OVER (ORDER BY total_profit DESC
                          ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS running_total_profit
FROM agg
ORDER BY total_profit DESC
LIMIT 100

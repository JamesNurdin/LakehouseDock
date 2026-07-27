WITH sales_base AS (
  SELECT
    cs.cs_order_number,
    cs.cs_sold_date_sk,
    cs.cs_quantity,
    cs.cs_net_profit,
    cs.cs_ship_mode_sk,
    cs.cs_promo_sk,
    cs.cs_item_sk,
    cs.cs_net_paid,
    p.p_promo_name,
    p.p_discount_active,
    sm.sm_ship_mode_id,
    sm.sm_contract,
    cr.cr_return_amount,
    cr.cr_return_quantity
  FROM catalog_sales cs
  JOIN promotion p
    ON cs.cs_promo_sk = p.p_promo_sk
  JOIN ship_mode sm
    ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
  LEFT JOIN catalog_returns cr
    ON cr.cr_order_number = cs.cs_order_number
   AND cr.cr_item_sk = cs.cs_item_sk
  WHERE
    cs.cs_quantity > 5
    AND cs.cs_net_profit > 0
    AND p.p_discount_active = 'Y'
    AND sm.sm_contract = 'Ek'
    AND cs.cs_sold_date_sk BETWEEN 2450000 AND 2450100
    AND (cr.cr_return_amount IS NULL OR cr.cr_return_amount >= 0)
)
SELECT
  sb.cs_order_number,
  sb.p_promo_name,
  sb.sm_ship_mode_id,
  SUM(sb.cs_net_profit) AS total_profit,
  COUNT(*) AS sales_cnt,
  CASE
    WHEN SUM(COALESCE(sb.cr_return_amount, 0)) > 0 THEN 'Returned'
    ELSE 'No Return'
  END AS return_status,
  (SELECT AVG(cs2.cs_net_profit)
     FROM catalog_sales cs2
    WHERE cs2.cs_promo_sk = sb.cs_promo_sk) AS avg_profit_per_promo,
  RANK() OVER (PARTITION BY sb.sm_ship_mode_id ORDER BY SUM(sb.cs_net_profit) DESC) AS profit_rank_per_shipmode
FROM sales_base sb
GROUP BY
  sb.cs_order_number,
  sb.p_promo_name,
  sb.sm_ship_mode_id,
  sb.sm_contract,
  sb.cs_promo_sk
ORDER BY profit_rank_per_shipmode, total_profit DESC
LIMIT 100

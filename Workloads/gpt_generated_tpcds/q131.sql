WITH sales_agg AS (
    SELECT
        cs.cs_call_center_sk   AS call_center_sk,
        cs.cs_promo_sk         AS promo_sk,
        cs.cs_ship_mode_sk     AS ship_mode_sk,
        SUM(cs.cs_net_paid)    AS total_net_paid,
        SUM(cs.cs_net_profit)  AS total_net_profit,
        COUNT(DISTINCT cs.cs_order_number) AS total_orders,
        SUM(cs.cs_quantity)    AS total_quantity
    FROM catalog_sales cs
    WHERE cs.cs_sold_date_sk >= 2450000
      AND cs.cs_sold_date_sk < 2451000
    GROUP BY cs.cs_call_center_sk, cs.cs_promo_sk, cs.cs_ship_mode_sk
),
returns_agg AS (
    SELECT
        cr.cr_call_center_sk   AS call_center_sk,
        cs.cs_promo_sk         AS promo_sk,
        cs.cs_ship_mode_sk     AS ship_mode_sk,
        SUM(cr.cr_return_amount) AS total_return_amount,
        SUM(cr.cr_net_loss)       AS total_return_loss,
        COUNT(DISTINCT cr.cr_order_number) AS total_return_orders,
        SUM(cr.cr_return_quantity) AS total_return_quantity
    FROM catalog_returns cr
    JOIN catalog_sales cs
      ON cr.cr_order_number = cs.cs_order_number
    WHERE cr.cr_returned_date_sk >= 2450000
      AND cr.cr_returned_date_sk < 2451000
    GROUP BY cr.cr_call_center_sk, cs.cs_promo_sk, cs.cs_ship_mode_sk
)
SELECT
    cc.cc_name                     AS call_center_name,
    p.p_promo_name                 AS promotion_name,
    sm.sm_type                     AS ship_mode_type,
    s.total_net_paid,
    s.total_net_profit,
    r.total_return_amount,
    r.total_return_loss,
    (s.total_net_profit - r.total_return_loss) AS net_profit_after_returns,
    s.total_orders,
    r.total_return_orders
FROM sales_agg   s
JOIN returns_agg r
  ON s.call_center_sk = r.call_center_sk
 AND s.promo_sk       = r.promo_sk
 AND s.ship_mode_sk   = r.ship_mode_sk
JOIN call_center cc
  ON s.call_center_sk = cc.cc_call_center_sk
JOIN promotion   p
  ON s.promo_sk       = p.p_promo_sk
JOIN ship_mode   sm
  ON s.ship_mode_sk   = sm.sm_ship_mode_sk
ORDER BY net_profit_after_returns DESC
LIMIT 100

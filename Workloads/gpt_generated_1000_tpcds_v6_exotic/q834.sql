/* goal: Analyze net loss from catalog returns and net profit from catalog sales by warehouse and promotion, focusing on high‑value, low‑risk customers and specific promotion channels. */
WITH joined AS (
    SELECT
        cr.cr_order_number                AS order_number,
        cr.cr_return_quantity             AS return_quantity,
        cr.cr_net_loss                    AS net_loss,
        cs.cs_net_profit                  AS net_profit,
        cs.cs_ext_ship_cost               AS ext_ship_cost,
        cd.cd_credit_rating               AS credit_rating,
        cd.cd_purchase_estimate           AS purchase_estimate,
        p.p_promo_name                    AS promo_name,
        p.p_channel_event                 AS channel_event,
        p.p_channel_catalog               AS channel_catalog,
        p.p_discount_active               AS discount_active,
        w.w_warehouse_name                AS warehouse_name,
        w.w_state                         AS warehouse_state
    FROM catalog_returns cr
    JOIN catalog_sales cs
        ON cr.cr_order_number = cs.cs_order_number
       AND cr.cr_item_sk       = cs.cs_item_sk
    JOIN customer_demographics cd
        ON cr.cr_refunded_cdemo_sk = cd.cd_demo_sk
    JOIN promotion p
        ON cs.cs_promo_sk = p.p_promo_sk
    JOIN warehouse w
        ON cs.cs_warehouse_sk = w.w_warehouse_sk
    WHERE cd.cd_credit_rating IN ('Good', 'Low Risk')
      AND cd.cd_purchase_estimate >= 4000
      AND p.p_channel_event = 'N'
      AND p.p_channel_catalog = 'N'
      AND cs.cs_ext_ship_cost > 0
      AND w.w_state = 'CA'
      AND EXISTS (
          SELECT 1
          FROM promotion p2
          WHERE p2.p_promo_sk = cs.cs_promo_sk
            AND p2.p_discount_active = 'Y'
      )
)
SELECT
    warehouse_name,
    promo_name,
    COUNT(DISTINCT order_number)                 AS orders,
    SUM(net_loss)                                 AS total_net_loss,
    SUM(net_profit)                               AS total_net_profit,
    AVG(ext_ship_cost)                            AS avg_ship_cost,
    CASE WHEN GROUPING(warehouse_name) = 1 THEN 'ALL_WAREHOUSES' ELSE warehouse_name END AS warehouse_group,
    CASE WHEN GROUPING(promo_name) = 1 THEN 'ALL_PROMOS' ELSE promo_name END AS promo_group
FROM joined
GROUP BY ROLLUP (warehouse_name, promo_name)
HAVING SUM(net_loss) > (
    SELECT AVG(cr_net_loss)
    FROM catalog_returns
)
ORDER BY total_net_loss DESC
LIMIT 100

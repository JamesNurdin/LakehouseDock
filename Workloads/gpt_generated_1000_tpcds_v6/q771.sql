WITH ws_agg AS (
    SELECT
        ws_item_sk,
        ws_ship_mode_sk,
        ws_warehouse_sk,
        ws_sold_time_sk,
        ws_web_site_sk,
        SUM(ws_net_profit) AS total_net_profit,
        COUNT(*) AS sales_cnt
    FROM web_sales
    WHERE ws_quantity BETWEEN 1 AND 100
      AND ws_ext_discount_amt < 3000
      AND ws_coupon_amt > 500
      AND ws_ext_tax >= 0
      AND ws_net_paid_inc_tax > 0
      AND ws_ext_ship_cost IS NOT NULL
    GROUP BY ws_item_sk, ws_ship_mode_sk, ws_warehouse_sk, ws_sold_time_sk, ws_web_site_sk
),
returns_agg AS (
    SELECT
        cr_item_sk,
        cr_ship_mode_sk,
        SUM(cr_return_amount) AS total_return_amount,
        COUNT(*) AS return_cnt
    FROM catalog_returns
    WHERE cr_return_quantity > 0
      AND cr_return_tax > 0
      AND cr_return_amt_inc_tax > 0
      AND cr_fee BETWEEN 0 AND 50
      AND cr_return_ship_cost < 100
      AND cr_net_loss > 0
    GROUP BY cr_item_sk, cr_ship_mode_sk
)
SELECT DISTINCT
    ws_agg.ws_item_sk,
    i.i_product_name,
    i.i_color,
    sm.sm_type,
    w.w_warehouse_name,
    td.t_sub_shift,
    ws_agg.total_net_profit,
    ws_agg.sales_cnt,
    ra.total_return_amount,
    ra.return_cnt,
    ws_agg.total_net_profit / NULLIF(ws_agg.sales_cnt, 0) AS avg_profit_per_sale,
    (ws_agg.total_net_profit - COALESCE(ra.total_return_amount, 0)) AS net_profit_after_returns
FROM ws_agg
JOIN item i
    ON ws_agg.ws_item_sk = i.i_item_sk
JOIN ship_mode sm
    ON ws_agg.ws_ship_mode_sk = sm.sm_ship_mode_sk
JOIN warehouse w
    ON ws_agg.ws_warehouse_sk = w.w_warehouse_sk
JOIN time_dim td
    ON ws_agg.ws_sold_time_sk = td.t_time_sk
JOIN web_site web
    ON ws_agg.ws_web_site_sk = web.web_site_sk
JOIN catalog_returns cr
    ON cr.cr_item_sk = i.i_item_sk
JOIN catalog_page cp
    ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
JOIN call_center cc
    ON cr.cr_call_center_sk = cc.cc_call_center_sk
LEFT JOIN returns_agg ra
    ON ra.cr_item_sk = i.i_item_sk
   AND ra.cr_ship_mode_sk = sm.sm_ship_mode_sk
WHERE NOT EXISTS (
        SELECT 1
        FROM catalog_returns cr2
        WHERE cr2.cr_item_sk = i.i_item_sk
          AND cr2.cr_return_amount > 5000
    )
  AND cc.cc_state = 'CA'
  AND sm.sm_carrier = 'UPS'
  AND td.t_hour BETWEEN 8 AND 20
  AND w.w_state = 'CA'
  AND cp.cp_department = 'Electronics'
  AND i.i_color = 'Red'
  AND ws_agg.sales_cnt > 5
ORDER BY net_profit_after_returns DESC
LIMIT 100

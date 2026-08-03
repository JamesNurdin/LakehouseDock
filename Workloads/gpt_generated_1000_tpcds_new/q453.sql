WITH
  -- Branch A: catalog returns and its related dimensions
  branch_a AS (
    SELECT
      w.w_warehouse_sk                                          AS warehouse_sk,
      w.w_state                                                AS warehouse_state,
      cr.cr_returned_date_sk                                   AS date_sk,
      cr.cr_return_amount                                      AS metric_amount,
      cr.cr_return_quantity                                    AS metric_quantity,
      cc.cc_name                                               AS extra_info,
      (
        SELECT SUM(inv_quantity_on_hand)
        FROM inventory inv
        WHERE inv.inv_warehouse_sk = w.w_warehouse_sk
      )                                                       AS total_inventory,
      ROW_NUMBER() OVER (PARTITION BY w.w_warehouse_sk ORDER BY cr.cr_return_amount DESC) AS rn
    FROM catalog_returns cr
    JOIN warehouse w               ON cr.cr_warehouse_sk = w.w_warehouse_sk
    JOIN call_center cc            ON cr.cr_call_center_sk = cc.cc_call_center_sk
    JOIN catalog_page cp            ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN time_dim t                ON cr.cr_returned_time_sk = t.t_time_sk
    JOIN customer_address ca_ref   ON cr.cr_refunded_addr_sk = ca_ref.ca_address_sk
    JOIN customer_address ca_ret   ON cr.cr_returning_addr_sk = ca_ret.ca_address_sk
    JOIN customer_demographics cd_ref ON cr.cr_refunded_cdemo_sk = cd_ref.cd_demo_sk
    JOIN customer_demographics cd_ret ON cr.cr_returning_cdemo_sk = cd_ret.cd_demo_sk
    WHERE w.w_state = 'CA'
      AND t.t_hour BETWEEN 9 AND 17
      AND cc.cc_country = 'United States'
      AND cr.cr_return_amount > 0
  ),

  -- Branch B: web sales and its related dimensions, unnesting the URL path
  branch_b AS (
    SELECT
      w.w_warehouse_sk                                          AS warehouse_sk,
      w.w_state                                                AS warehouse_state,
      ws.ws_sold_date_sk                                       AS date_sk,
      ws.ws_net_paid                                           AS metric_amount,
      ws.ws_quantity                                           AS metric_quantity,
      url_part                                                 AS extra_info,
      (
        SELECT SUM(inv_quantity_on_hand)
        FROM inventory inv
        WHERE inv.inv_warehouse_sk = w.w_warehouse_sk
      )                                                       AS total_inventory,
      ROW_NUMBER() OVER (PARTITION BY w.w_warehouse_sk ORDER BY ws.ws_net_paid DESC) AS rn
    FROM web_sales ws
    JOIN warehouse w               ON ws.ws_warehouse_sk = w.w_warehouse_sk
    JOIN time_dim t                ON ws.ws_sold_time_sk = t.t_time_sk
    JOIN web_page wp               ON ws.ws_web_page_sk = wp.wp_web_page_sk
    JOIN customer_address ca_bill  ON ws.ws_bill_addr_sk = ca_bill.ca_address_sk
    JOIN customer_address ca_ship  ON ws.ws_ship_addr_sk = ca_ship.ca_address_sk
    JOIN customer_demographics cd_bill ON ws.ws_bill_cdemo_sk = cd_bill.cd_demo_sk
    JOIN customer_demographics cd_ship ON ws.ws_ship_cdemo_sk = cd_ship.cd_demo_sk
    LEFT JOIN web_returns wr        ON wr.wr_order_number = ws.ws_order_number
    CROSS JOIN UNNEST(split(wp.wp_url, '/')) AS t(url_part)
    WHERE w.w_state = 'CA'
      AND t.t_hour BETWEEN 9 AND 17
      AND wp.wp_type = 'product'
      AND ws.ws_quantity > 1
      AND NOT EXISTS (
        SELECT 1 FROM web_returns wr2 WHERE wr2.wr_order_number = ws.ws_order_number
      )
  )

SELECT
  warehouse_sk,
  warehouse_state,
  date_sk,
  metric_amount,
  metric_quantity,
  extra_info,
  total_inventory,
  rn
FROM (
  SELECT * FROM branch_a
  UNION DISTINCT
  SELECT * FROM branch_b
) AS combined
ORDER BY total_inventory DESC, rn
LIMIT 100

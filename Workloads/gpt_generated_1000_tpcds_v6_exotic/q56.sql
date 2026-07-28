WITH
  sub_a AS (
    SELECT
      cs.cs_order_number        AS order_number,
      cs.cs_sold_date_sk       AS sold_date_sk,
      cs.cs_net_profit         AS net_amount,
      c.c_customer_id          AS customer_id,
      cd.cd_gender             AS gender,
      cc.cc_name               AS channel_desc,
      sm.sm_type               AS ship_mode,
      w.w_warehouse_name       AS warehouse_name,
      sr.sr_return_quantity    AS return_quantity,
      r2.r_reason_desc         AS return_reason,
      cs.cs_quantity           AS quantity,
      cs.cs_ext_sales_price    AS ext_sales_price
    FROM catalog_sales cs
    JOIN time_dim td               ON cs.cs_sold_time_sk   = td.t_time_sk
    JOIN customer c                ON cs.cs_bill_customer_sk = c.c_customer_sk
    JOIN customer_demographics cd  ON cs.cs_bill_cdemo_sk   = cd.cd_demo_sk
    JOIN call_center cc            ON cs.cs_call_center_sk  = cc.cc_call_center_sk
    JOIN catalog_page cp           ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN ship_mode sm              ON cs.cs_ship_mode_sk    = sm.sm_ship_mode_sk
    JOIN warehouse w               ON cs.cs_warehouse_sk    = w.w_warehouse_sk
    LEFT JOIN inventory inv        ON w.w_warehouse_sk      = inv.inv_warehouse_sk
    LEFT JOIN catalog_returns cr   ON cs.cs_order_number   = cr.cr_order_number
    LEFT JOIN reason r             ON cr.cr_reason_sk       = r.r_reason_sk
    LEFT JOIN store_returns sr     ON td.t_time_sk         = sr.sr_return_time_sk
    LEFT JOIN store s              ON sr.sr_store_sk       = s.s_store_sk
    LEFT JOIN reason r2            ON sr.sr_reason_sk       = r2.r_reason_sk
    WHERE s.s_country = 'United States'
      AND s.s_rec_start_date >= DATE '1999-01-01'
      AND s.s_rec_start_date <  DATE '2000-01-01'
      AND cs.cs_quantity > 5
      AND cp.cp_department = 'Sports'
  ),
  sub_b AS (
    SELECT
      ws.ws_order_number        AS order_number,
      ws.ws_sold_date_sk        AS sold_date_sk,
      ws.ws_net_paid            AS net_amount,
      c.c_customer_id           AS customer_id,
      cd.cd_gender              AS gender,
      wp.wp_url                 AS channel_desc,
      sm.sm_type                AS ship_mode,
      w.w_warehouse_name        AS warehouse_name,
      wr.wr_return_quantity     AS return_quantity,
      r.r_reason_desc           AS return_reason,
      ws.ws_quantity            AS quantity,
      ws.ws_ext_sales_price     AS ext_sales_price
    FROM web_sales ws
    JOIN time_dim td               ON ws.ws_sold_time_sk   = td.t_time_sk
    JOIN customer c                ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN customer_demographics cd  ON ws.ws_bill_cdemo_sk   = cd.cd_demo_sk
    JOIN ship_mode sm              ON ws.ws_ship_mode_sk    = sm.sm_ship_mode_sk
    JOIN warehouse w               ON ws.ws_warehouse_sk    = w.w_warehouse_sk
    JOIN web_page wp               ON ws.ws_web_page_sk    = wp.wp_web_page_sk
    LEFT JOIN web_returns wr      ON ws.ws_order_number   = wr.wr_order_number
    LEFT JOIN reason r            ON wr.wr_reason_sk       = r.r_reason_sk
    WHERE wp.wp_rec_end_date BETWEEN DATE '1999-09-01' AND DATE '1999-09-30'
      AND ws.ws_quantity > 3
      AND ws.ws_ext_sales_price > 1000
  ),
  combined AS (
    SELECT * FROM sub_a
    UNION ALL
    SELECT * FROM sub_b
  ),
  ranked AS (
    SELECT
      *,
      ROW_NUMBER() OVER (PARTITION BY customer_id ORDER BY net_amount DESC) AS rn
    FROM combined
  )
SELECT
  order_number,
  sold_date_sk,
  net_amount,
  customer_id,
  gender,
  channel_desc,
  ship_mode,
  warehouse_name,
  return_quantity,
  return_reason,
  quantity,
  ext_sales_price
FROM ranked
WHERE rn <= 5
ORDER BY net_amount DESC
LIMIT 100

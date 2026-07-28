WITH cat AS (
  SELECT
    cs.cs_sold_date_sk                AS sold_date_sk,
    cs.cs_order_number                AS order_number,
    cs.cs_quantity                    AS quantity,
    cs.cs_net_profit                  AS net_profit,
    cc.cc_name                        AS call_center_name,
    cp.cp_department                  AS catalog_department,
    i.i_brand                         AS item_brand,
    w.w_warehouse_name                AS warehouse_name,
    sm.sm_carrier                     AS ship_carrier,
    td.t_hour                         AS hour_of_day,
    inv.inv_quantity_on_hand          AS inventory_on_hand,
    c.c_first_name                    AS cust_first_name,
    c.c_last_name                     AS cust_last_name,
    cd.cd_gender                      AS cust_gender,
    CAST(NULL AS VARCHAR)            AS return_reason,
    CAST(NULL AS INTEGER)            AS return_qty,
    CAST(NULL AS DECIMAL(7,2))       AS return_loss,
    'catalog'                         AS src
  FROM catalog_sales cs
  JOIN call_center cc      ON cs.cs_call_center_sk = cc.cc_call_center_sk
  JOIN catalog_page cp      ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
  JOIN item i               ON cs.cs_item_sk = i.i_item_sk
  JOIN warehouse w          ON cs.cs_warehouse_sk = w.w_warehouse_sk
  JOIN ship_mode sm         ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
  JOIN time_dim td          ON cs.cs_sold_time_sk = td.t_time_sk
  JOIN customer c           ON cs.cs_bill_customer_sk = c.c_customer_sk
  JOIN customer_demographics cd ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
  JOIN inventory inv        ON i.i_item_sk = inv.inv_item_sk
                              AND w.w_warehouse_sk = inv.inv_warehouse_sk
),
web AS (
  SELECT
    ws.ws_sold_date_sk                AS sold_date_sk,
    ws.ws_order_number                AS order_number,
    ws.ws_quantity                    AS quantity,
    ws.ws_net_profit                  AS net_profit,
    CAST(NULL AS VARCHAR)            AS call_center_name,
    wp.wp_type                        AS catalog_department,
    i.i_brand                         AS item_brand,
    w.w_warehouse_name                AS warehouse_name,
    sm.sm_carrier                     AS ship_carrier,
    td.t_hour                         AS hour_of_day,
    CAST(NULL AS INTEGER)            AS inventory_on_hand,
    c.c_first_name                    AS cust_first_name,
    c.c_last_name                     AS cust_last_name,
    cd.cd_gender                      AS cust_gender,
    r.r_reason_desc                   AS return_reason,
    wr.wr_return_quantity             AS return_qty,
    wr.wr_net_loss                    AS return_loss,
    'web'                             AS src
  FROM web_sales ws
  JOIN web_page wp      ON ws.ws_web_page_sk = wp.wp_web_page_sk
  JOIN item i           ON ws.ws_item_sk = i.i_item_sk
  JOIN warehouse w      ON ws.ws_warehouse_sk = w.w_warehouse_sk
  JOIN ship_mode sm     ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
  JOIN time_dim td      ON ws.ws_sold_time_sk = td.t_time_sk
  JOIN customer c       ON ws.ws_bill_customer_sk = c.c_customer_sk
  JOIN customer_demographics cd ON ws.ws_bill_cdemo_sk = cd.cd_demo_sk
  LEFT JOIN web_returns wr ON ws.ws_order_number = wr.wr_order_number
  LEFT JOIN reason r        ON wr.wr_reason_sk = r.r_reason_sk
)
SELECT
  src,
  order_number,
  quantity,
  net_profit,
  call_center_name,
  catalog_department,
  item_brand,
  warehouse_name,
  ship_carrier,
  hour_of_day,
  inventory_on_hand,
  cust_first_name,
  cust_last_name,
  cust_gender,
  return_reason,
  return_qty,
  return_loss,
  ROW_NUMBER() OVER (PARTITION BY src ORDER BY net_profit DESC) AS profit_rank,
  DENSE_RANK() OVER (PARTITION BY src ORDER BY quantity DESC)   AS qty_rank
FROM (
  SELECT * FROM cat
  UNION ALL
  SELECT * FROM web
) AS u
WHERE (
        src = 'catalog' AND quantity > 2
      ) OR (
        src = 'web'     AND quantity > 1
      ) OR (
        hour_of_day BETWEEN 8 AND 12
      )
ORDER BY src, profit_rank
LIMIT 100

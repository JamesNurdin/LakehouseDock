WITH
  cs_sample AS (
    SELECT *
    FROM catalog_sales
    TABLESAMPLE BERNOULLI (10)
  ),
  ws_sample AS (
    SELECT *
    FROM web_sales
    TABLESAMPLE BERNOULLI (10)
  )
SELECT
  state,
  SUM(total_sales)                AS total_sales,
  SUM(total_orders)               AS total_orders,
  AVG(avg_quantity)               AS avg_quantity,
  COUNT(*) FILTER (WHERE sales_category = 'High') AS high_sales_states,
  MAX(aux_total_sales)            AS max_aux_sales
FROM (
  -- Catalog channel
  SELECT
    ca.ca_state                               AS state,
    SUM(cs.cs_ext_sales_price)                AS total_sales,
    COUNT(DISTINCT cs.cs_order_number)        AS total_orders,
    AVG(cs.cs_quantity)                       AS avg_quantity,
    CASE WHEN SUM(cs.cs_ext_sales_price) > 100000 THEN 'High' ELSE 'Low' END AS sales_category,
    ls.aux_total_sales                        AS aux_total_sales
  FROM cs_sample cs
  JOIN catalog_page cp        ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
  JOIN promotion p            ON cs.cs_promo_sk        = p.p_promo_sk
  JOIN ship_mode sm           ON cs.cs_ship_mode_sk    = sm.sm_ship_mode_sk
  JOIN warehouse w            ON cs.cs_warehouse_sk    = w.w_warehouse_sk
  JOIN customer_demographics cd ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
  JOIN customer_address ca   ON cs.cs_bill_addr_sk   = ca.ca_address_sk
  JOIN store_returns sr      ON sr.sr_cdemo_sk = cd.cd_demo_sk
                              AND sr.sr_addr_sk = ca.ca_address_sk
  CROSS JOIN LATERAL (
    SELECT SUM(cs2.cs_ext_sales_price) AS aux_total_sales
    FROM catalog_sales cs2
    WHERE cs2.cs_ship_mode_sk = cs.cs_ship_mode_sk
  ) ls
  WHERE cd.cd_education_status = 'College'
    AND cd.cd_purchase_estimate > 5000
    AND sm.sm_carrier = 'FEDEX'
    AND cs.cs_promo_sk IN (
      SELECT p2.p_promo_sk
      FROM promotion p2
      WHERE p2.p_discount_active = 'Y'
    )
  GROUP BY ca.ca_state, ls.aux_total_sales

  UNION DISTINCT

  -- Web channel
  SELECT
    ca.ca_state                               AS state,
    SUM(ws.ws_ext_sales_price)                AS total_sales,
    COUNT(DISTINCT ws.ws_order_number)        AS total_orders,
    AVG(ws.ws_quantity)                       AS avg_quantity,
    CASE WHEN SUM(ws.ws_ext_sales_price) > 100000 THEN 'High' ELSE 'Low' END AS sales_category,
    ls.aux_total_sales                        AS aux_total_sales
  FROM ws_sample ws
  JOIN promotion p            ON ws.ws_promo_sk        = p.p_promo_sk
  JOIN ship_mode sm           ON ws.ws_ship_mode_sk    = sm.sm_ship_mode_sk
  JOIN warehouse w            ON ws.ws_warehouse_sk    = w.w_warehouse_sk
  JOIN customer_demographics cd ON ws.ws_bill_cdemo_sk = cd.cd_demo_sk
  JOIN customer_address ca   ON ws.ws_bill_addr_sk   = ca.ca_address_sk
  CROSS JOIN LATERAL (
    SELECT SUM(ws2.ws_ext_sales_price) AS aux_total_sales
    FROM web_sales ws2
    WHERE ws2.ws_warehouse_sk = ws.ws_warehouse_sk
  ) ls
  WHERE cd.cd_education_status = 'College'
    AND cd.cd_purchase_estimate > 5000
    AND sm.sm_carrier = 'FEDEX'
    AND ws.ws_promo_sk IN (
      SELECT p2.p_promo_sk
      FROM promotion p2
      WHERE p2.p_discount_active = 'Y'
    )
  GROUP BY ca.ca_state, ls.aux_total_sales
) u
GROUP BY state
ORDER BY total_sales DESC
LIMIT 20

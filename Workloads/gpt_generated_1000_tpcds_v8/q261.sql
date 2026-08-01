WITH
  ws_sample AS (
    SELECT *
    FROM web_sales
    TABLESAMPLE BERNOULLI (10)
    WHERE ws_list_price > 100
      AND ws_wholesale_cost < 50
  ),
  store_catalog_combined AS (
    SELECT
      sr.sr_addr_sk,
      sr.sr_return_ship_cost,
      cr.cr_refunded_addr_sk,
      cr.cr_return_amount,
      cr.cr_order_number,
      cr.cr_ship_mode_sk
    FROM store_returns sr
    FULL OUTER JOIN catalog_returns cr
      ON sr.sr_addr_sk = cr.cr_refunded_addr_sk
    WHERE (sr.sr_return_ship_cost > 20 OR cr.cr_return_amount > 10)
  )
SELECT
  city,
  ship_type,
  SUM(net_paid)               AS total_net_paid,
  COUNT(DISTINCT order_number) AS unique_orders,
  AVG(list_price)             AS avg_list_price,
  MAX(return_ship_cost)       AS max_return_ship_cost,
  MIN(return_amount)          AS min_return_amount
FROM (
  -- Part 1 – web_sales based rows
  SELECT
    ca_bill.ca_city                              AS city,
    sm.sm_type                                   AS ship_type,
    ws.ws_net_paid                               AS net_paid,
    ws.ws_order_number                           AS order_number,
    ws.ws_list_price                             AS list_price,
    COALESCE(sc.sr_return_ship_cost, 0)          AS return_ship_cost,
    COALESCE(sc.cr_return_amount, 0)             AS return_amount
  FROM ws_sample ws
  JOIN customer_address ca_bill
    ON ws.ws_bill_addr_sk = ca_bill.ca_address_sk
  JOIN customer_address ca_ship
    ON ws.ws_ship_addr_sk = ca_ship.ca_address_sk
  JOIN ship_mode sm
    ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
  JOIN web_site ws_site
    ON ws.ws_web_site_sk = ws_site.web_site_sk
  LEFT JOIN (
    SELECT
      sc_comb.sr_addr_sk,
      sc_comb.sr_return_ship_cost,
      sc_comb.cr_refunded_addr_sk,
      sc_comb.cr_return_amount,
      sc_comb.cr_ship_mode_sk
    FROM store_catalog_combined sc_comb
  ) sc
    ON sc.sr_addr_sk = ca_ship.ca_address_sk
   OR sc.cr_refunded_addr_sk = ca_bill.ca_address_sk
  WHERE ws_site.web_city = 'Glenwood'
    AND sm.sm_type = 'AIR'
    AND NOT EXISTS (
          SELECT 1 FROM catalog_returns cr2
          WHERE cr2.cr_order_number = ws.ws_order_number
        )
  UNION DISTINCT
  -- Part 2 – rows that exist only in the store‑catalog combined set
  SELECT
    ca.ca_city                                   AS city,
    sm.sm_type                                   AS ship_type,
    0.0                                          AS net_paid,
    NULL                                         AS order_number,
    0.0                                          AS list_price,
    COALESCE(sc.sr_return_ship_cost, 0)          AS return_ship_cost,
    COALESCE(sc.cr_return_amount, 0)             AS return_amount
  FROM store_catalog_combined sc
  JOIN customer_address ca
    ON ca.ca_address_sk = COALESCE(sc.sr_addr_sk, sc.cr_refunded_addr_sk)
  LEFT JOIN ship_mode sm
    ON sm.sm_ship_mode_sk = sc.cr_ship_mode_sk
) agg
GROUP BY city, ship_type
ORDER BY total_net_paid DESC
LIMIT 100

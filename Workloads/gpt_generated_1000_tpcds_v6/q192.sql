WITH
  promoted_air AS (
    SELECT
      'Promoted_Air' AS sales_category,
      d.d_year,
      SUM(ws.ws_net_profit) AS total_profit
    FROM
      tpcds.web_sales ws
      JOIN tpcds.date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
      JOIN tpcds.ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
      JOIN tpcds.promotion p ON ws.ws_promo_sk = p.p_promo_sk
    WHERE
      p.p_cost > 500
      AND sm.sm_code = 'AIR'
      AND d.d_date BETWEEN DATE '2000-01-01' AND DATE '2000-12-31'
    GROUP BY
      d.d_year
    HAVING
      SUM(ws.ws_net_profit) > 10000
  ),
  nonpromoted_sea AS (
    SELECT
      'NonPromoted_Sea' AS sales_category,
      d.d_year,
      SUM(ws.ws_net_profit) AS total_profit
    FROM
      tpcds.web_sales ws
      JOIN tpcds.date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
      JOIN tpcds.ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
    WHERE
      ws.ws_promo_sk IS NULL
      AND sm.sm_code = 'SEA'
      AND d.d_date BETWEEN DATE '2000-01-01' AND DATE '2000-12-31'
    GROUP BY
      d.d_year
    HAVING
      SUM(ws.ws_net_profit) > 10000
  )
SELECT
  sales_category,
  d_year,
  total_profit
FROM
  promoted_air
UNION ALL
SELECT
  sales_category,
  d_year,
  total_profit
FROM
  nonpromoted_sea
LIMIT 100

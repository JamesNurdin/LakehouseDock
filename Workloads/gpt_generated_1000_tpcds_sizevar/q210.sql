WITH
  base AS (
    SELECT
      ws.ws_web_site_sk,
      ws.ws_sold_date_sk,
      ws.ws_quantity,
      ws.ws_net_paid_inc_ship,
      ws.ws_sales_price,
      ws.ws_ext_tax,
      ws.ws_net_profit,
      web.web_county,
      web.web_zip,
      web.web_tax_percentage
    FROM
      web_sales ws
      JOIN web_site web ON ws.ws_web_site_sk = web.web_site_sk
    WHERE
      ws.ws_sold_date_sk BETWEEN 2451400 AND 2452600          -- predicate 1
      AND ws.ws_quantity > 1                                 -- predicate 2
      AND ws.ws_net_paid_inc_ship > 500                      -- predicate 3
      AND web.web_county IN ('Bronx County', 'Jackson County') -- predicate 4
      AND web.web_zip NOT LIKE '9%'                         -- predicate 5
      AND web.web_tax_percentage >= 0.05                    -- predicate 6
  ),
  agg1 AS (
    SELECT
      ws_web_site_sk,
      COUNT(*) AS order_cnt,
      SUM(ws_net_paid_inc_ship) AS total_paid,
      AVG(ws_net_profit) AS avg_profit,
      SUM(ws_sales_price) AS sum_sales_price,
      array_agg(ws_quantity) AS qty_array
    FROM
      base
    GROUP BY
      ws_web_site_sk
  ),
  max_total AS (
    SELECT MAX(total_paid) AS max_total FROM agg1
  )
SELECT
  a.ws_web_site_sk,
  a.order_cnt,
  a.total_paid,
  a.avg_profit,
  a.sum_sales_price,
  CASE
    WHEN a.total_paid = (SELECT max_total FROM max_total) THEN 'TOP'
    ELSE 'OTHER'
  END AS tier,
  u.qty AS quantity_value,
  t.tax_sum
FROM
  agg1 a
  -- expand the array of quantities per site
  CROSS JOIN LATERAL (
    SELECT qty FROM UNNEST(a.qty_array) AS t(qty)
  ) u
  -- bring in total tax per site from the base rows
  LEFT JOIN (
    SELECT ws_web_site_sk, SUM(ws_ext_tax) AS tax_sum
    FROM base
    GROUP BY ws_web_site_sk
  ) t ON t.ws_web_site_sk = a.ws_web_site_sk
WHERE
  a.total_paid > (SELECT max_total FROM max_total) * 0.9
ORDER BY
  a.total_paid DESC
LIMIT 100

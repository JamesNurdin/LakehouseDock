WITH catalog_sub AS (
  SELECT
    i.i_item_id               AS item_id,
    d.d_date                  AS sale_date,
    cs.cs_ext_sales_price     AS sales_amount,
    cs.cs_net_profit          AS profit,
    'catalog'                 AS channel,
    cs.cs_bill_addr_sk        AS bill_addr_sk
  FROM catalog_sales cs
  JOIN date_dim d          ON cs.cs_sold_date_sk = d.d_date_sk
  JOIN item i              ON cs.cs_item_sk = i.i_item_sk
  JOIN promotion p         ON cs.cs_promo_sk = p.p_promo_sk
  JOIN customer_address ca ON cs.cs_bill_addr_sk = ca.ca_address_sk
  WHERE d.d_year = 2001
    AND p.p_discount_active = 'Y'
    AND cs.cs_ext_sales_price > 0
),
web_sub AS (
  SELECT
    i.i_item_id               AS item_id,
    d.d_date                  AS sale_date,
    ws.ws_ext_sales_price     AS sales_amount,
    ws.ws_net_profit          AS profit,
    'web'                     AS channel,
    ws.ws_bill_addr_sk        AS bill_addr_sk
  FROM web_sales ws
  JOIN date_dim d          ON ws.ws_sold_date_sk = d.d_date_sk
  JOIN item i              ON ws.ws_item_sk = i.i_item_sk
  JOIN promotion p         ON ws.ws_promo_sk = p.p_promo_sk
  JOIN customer_address ca ON ws.ws_bill_addr_sk = ca.ca_address_sk
  WHERE d.d_year = 2001
    AND p.p_discount_active = 'Y'
    AND ws.ws_ext_sales_price > 0
),
combined AS (
  SELECT * FROM catalog_sub
  UNION ALL
  SELECT * FROM web_sub
)
SELECT
  item_id,
  sale_date,
  channel,
  sales_amount,
  profit,
  CASE WHEN profit > 0 THEN 'Profit' ELSE 'Loss' END AS profit_flag,
  SUM(sales_amount) OVER (PARTITION BY item_id ORDER BY sale_date ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS running_sales
FROM combined
ORDER BY item_id, sale_date
LIMIT 100

WITH sales AS (
  SELECT
    d.d_year AS year,
    i.i_item_id AS item_id,
    i.i_item_desc AS item_desc,
    ss.ss_quantity AS quantity,
    ss.ss_net_profit AS net_profit,
    ss.ss_ext_discount_amt AS discount_amount,
    ss.ss_ext_sales_price AS sales_price,
    ss.ss_ext_tax AS tax_amount,
    'store' AS channel
  FROM store_sales ss
  JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
  JOIN item i ON ss.ss_item_sk = i.i_item_sk
  LEFT JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
  WHERE d.d_year BETWEEN 1999 AND 2002
    AND (p.p_discount_active = 'Y' OR p.p_discount_active IS NULL)
  UNION ALL
  SELECT
    d.d_year,
    i.i_item_id,
    i.i_item_desc,
    cs.cs_quantity,
    cs.cs_net_profit,
    cs.cs_ext_discount_amt,
    cs.cs_ext_sales_price,
    cs.cs_ext_tax,
    'catalog'
  FROM catalog_sales cs
  JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
  JOIN item i ON cs.cs_item_sk = i.i_item_sk
  LEFT JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
  WHERE d.d_year BETWEEN 1999 AND 2002
    AND (p.p_discount_active = 'Y' OR p.p_discount_active IS NULL)
  UNION ALL
  SELECT
    d.d_year,
    i.i_item_id,
    i.i_item_desc,
    ws.ws_quantity,
    ws.ws_net_profit,
    ws.ws_ext_discount_amt,
    ws.ws_ext_sales_price,
    ws.ws_ext_tax,
    'web'
  FROM web_sales ws
  JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
  JOIN item i ON ws.ws_item_sk = i.i_item_sk
  LEFT JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
  WHERE d.d_year BETWEEN 1999 AND 2002
    AND (p.p_discount_active = 'Y' OR p.p_discount_active IS NULL)
)
SELECT
  year,
  item_id,
  item_desc,
  SUM(quantity) AS total_quantity,
  SUM(net_profit) AS total_net_profit,
  SUM(discount_amount) AS total_discount,
  AVG(discount_amount / NULLIF(sales_price, 0)) AS avg_discount_rate,
  COUNT(DISTINCT channel) AS channels_sold
FROM sales
GROUP BY
  year,
  item_id,
  item_desc
HAVING SUM(net_profit) > 10000
ORDER BY total_net_profit DESC
LIMIT 100

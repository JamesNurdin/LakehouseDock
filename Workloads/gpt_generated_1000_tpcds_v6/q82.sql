SELECT DISTINCT
  order_num,
  item_id,
  brand,
  year_sold,
  quantity,
  net_paid,
  profit_category,
  promo_channel
FROM (
  SELECT
    ws.ws_order_number        AS order_num,
    i.i_item_id              AS item_id,
    i.i_brand                AS brand,
    d.d_year                 AS year_sold,
    ws.ws_quantity           AS quantity,
    ws.ws_net_paid           AS net_paid,
    CASE WHEN ws.ws_net_profit > 100 THEN 'High' ELSE 'Low' END AS profit_category,
    'Email'                  AS promo_channel
  FROM web_sales ws
  JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
  JOIN item i ON ws.ws_item_sk = i.i_item_sk
  JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
  WHERE p.p_channel_email = 'Y'
    AND d.d_year = 2001

  UNION ALL

  SELECT
    ws.ws_order_number        AS order_num,
    i.i_item_id              AS item_id,
    i.i_brand                AS brand,
    d.d_year                 AS year_sold,
    ws.ws_quantity           AS quantity,
    ws.ws_net_paid           AS net_paid,
    CASE WHEN ws.ws_net_profit > 100 THEN 'High' ELSE 'Low' END AS profit_category,
    'TV'                     AS promo_channel
  FROM web_sales ws
  JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
  JOIN item i ON ws.ws_item_sk = i.i_item_sk
  JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
  WHERE p.p_channel_tv = 'Y'
    AND d.d_year = 2001
) AS combined
ORDER BY net_paid DESC
LIMIT 100

SELECT
    'store' AS channel,
    i.i_category AS product_category,
    t.t_hour AS hour_of_day,
    SUM(ss.ss_ext_sales_price) AS total_sales,
    SUM(ss.ss_net_profit) AS total_profit,
    CASE WHEN SUM(ss.ss_net_profit) < 0 THEN 'Loss' ELSE 'Profit' END AS profit_flag,
    (SELECT AVG(ii.i_current_price) FROM item ii) AS avg_item_price_global
FROM store_sales ss
JOIN time_dim t
  ON ss.ss_sold_time_sk = t.t_time_sk
JOIN item i
  ON ss.ss_item_sk = i.i_item_sk
JOIN customer c
  ON ss.ss_customer_sk = c.c_customer_sk
JOIN customer_demographics cd
  ON ss.ss_cdemo_sk = cd.cd_demo_sk
WHERE t.t_hour BETWEEN 10 AND 18
  AND EXISTS (
        SELECT 1
        FROM store_returns sr
        WHERE sr.sr_item_sk = ss.ss_item_sk
          AND sr.sr_return_quantity > 0
      )
GROUP BY i.i_category, t.t_hour

UNION ALL

SELECT
    'web' AS channel,
    i.i_category AS product_category,
    t.t_hour AS hour_of_day,
    SUM(ws.ws_ext_sales_price) AS total_sales,
    SUM(ws.ws_net_profit) AS total_profit,
    CASE WHEN SUM(ws.ws_net_profit) < 0 THEN 'Loss' ELSE 'Profit' END AS profit_flag,
    (SELECT AVG(ii.i_current_price) FROM item ii) AS avg_item_price_global
FROM web_sales ws
JOIN time_dim t
  ON ws.ws_sold_time_sk = t.t_time_sk
JOIN item i
  ON ws.ws_item_sk = i.i_item_sk
JOIN customer c
  ON ws.ws_bill_customer_sk = c.c_customer_sk
JOIN customer_demographics cd
  ON ws.ws_bill_cdemo_sk = cd.cd_demo_sk
WHERE i.i_brand = 'BrandA'
  AND t.t_sub_shift = 'evening'
GROUP BY i.i_category, t.t_hour

ORDER BY total_sales DESC
LIMIT 100

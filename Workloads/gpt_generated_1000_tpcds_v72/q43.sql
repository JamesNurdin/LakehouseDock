WITH sales_base AS (
  SELECT
    cc.cc_rec_start_date,
    cc.cc_name,
    cs.cs_order_number,
    cs.cs_sold_date_sk,
    cs.cs_sold_time_sk,
    cs.cs_item_sk,
    cs.cs_ext_sales_price,
    cs.cs_net_profit,
    cr.cr_return_amount,
    i.i_item_id,
    i.i_brand,
    i.i_category,
    i.i_current_price,
    td.t_hour,
    td.t_meal_time,
    sr.sr_return_amt,
    ws.ws_quantity,
    ws.ws_ext_sales_price,
    ws.ws_net_profit,
    wr.wr_return_amt,
    ws.ws_web_site_sk,
    web.web_name,
    web.web_state,
    web.web_city
  FROM call_center cc
  JOIN catalog_sales cs
    ON cs.cs_call_center_sk = cc.cc_call_center_sk
  JOIN catalog_returns cr
    ON cr.cr_order_number = cs.cs_order_number
       AND cr.cr_item_sk = cs.cs_item_sk
  JOIN item i
    ON i.i_item_sk = cs.cs_item_sk
  JOIN time_dim td
    ON td.t_time_sk = cs.cs_sold_time_sk
  JOIN store_returns sr
    ON sr.sr_item_sk = i.i_item_sk
       AND sr.sr_return_time_sk = td.t_time_sk
  JOIN web_sales ws
    ON ws.ws_item_sk = i.i_item_sk
       AND ws.ws_sold_time_sk = td.t_time_sk
  JOIN web_returns wr
    ON wr.wr_item_sk = ws.ws_item_sk
       AND wr.wr_order_number = ws.ws_order_number
       AND wr.wr_returned_time_sk = td.t_time_sk
  JOIN web_site web
    ON web.web_site_sk = ws.ws_web_site_sk
),
brand_category_agg AS (
  SELECT
    i_brand,
    i_category,
    SUM(cs_net_profit) - SUM(cr_return_amount) - SUM(sr_return_amt) - SUM(wr_return_amt) AS net_profit_adj,
    COUNT(DISTINCT cs_order_number) AS orders_cnt,
    (SELECT MAX(ws2.web_tax_percentage)
       FROM web_site ws2
      WHERE ws2.web_city = sales_base.web_city) AS max_tax_city
  FROM sales_base
  WHERE cc_rec_start_date BETWEEN DATE '2001-01-01' AND DATE '2002-12-31'
    AND i_current_price > 100
    AND web_name IN ('site_1', 'site_3')
    AND web_state = 'WA'
    AND cs_ext_sales_price > 500
  GROUP BY i_brand, i_category, web_city
  HAVING SUM(cs_net_profit) > 0
)
SELECT
  AVG(net_profit_adj) AS avg_net_profit_adj,
  COUNT(*) AS brand_category_cnt
FROM brand_category_agg
WHERE orders_cnt > 10
ORDER BY avg_net_profit_adj DESC
LIMIT 100

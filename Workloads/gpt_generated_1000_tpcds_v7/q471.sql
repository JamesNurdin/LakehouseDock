WITH joined AS (
  SELECT
    d1.d_year,
    i.i_category,
    cs.cs_net_profit AS catalog_profit,
    ss.ss_net_profit AS store_profit,
    ws.ws_net_profit AS web_profit,
    cr.cr_net_loss AS return_loss,
    cc.cc_market_manager,
    r.r_reason_desc,
    ws_site.web_name AS web_site_name,
    wp.wp_type AS page_type
  FROM catalog_sales cs
  JOIN date_dim d1 ON cs.cs_sold_date_sk = d1.d_date_sk
  JOIN time_dim t1 ON cs.cs_sold_time_sk = t1.t_time_sk
  JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
  JOIN item i ON cs.cs_item_sk = i.i_item_sk
  JOIN household_demographics hd_bill ON cs.cs_bill_hdemo_sk = hd_bill.hd_demo_sk
  LEFT JOIN catalog_returns cr ON cr.cr_order_number = cs.cs_order_number
    AND cr.cr_item_sk = cs.cs_item_sk
  LEFT JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
  -- store_sales
  JOIN store_sales ss ON ss.ss_item_sk = i.i_item_sk
    AND ss.ss_sold_date_sk = d1.d_date_sk
  JOIN time_dim t2 ON ss.ss_sold_time_sk = t2.t_time_sk
  JOIN household_demographics hd_store ON ss.ss_hdemo_sk = hd_store.hd_demo_sk
  -- web_sales
  JOIN web_sales ws ON ws.ws_item_sk = i.i_item_sk
    AND ws.ws_sold_date_sk = d1.d_date_sk
  JOIN time_dim t3 ON ws.ws_sold_time_sk = t3.t_time_sk
  JOIN household_demographics hd_web ON ws.ws_bill_hdemo_sk = hd_web.hd_demo_sk
  JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
  JOIN web_site ws_site ON ws.ws_web_site_sk = ws_site.web_site_sk
  WHERE d1.d_year BETWEEN 1999 AND 2001
    AND i.i_current_price BETWEEN 100 AND 2000
    AND cc.cc_market_manager = 'John Doe'
    AND r.r_reason_desc LIKE '%Warranty%'
    AND ws_site.web_country = 'United States'
)
SELECT
  d_year,
  i_category,
  AVG(total_profit) AS avg_profit,
  SUM(total_profit) AS sum_profit,
  COUNT(*) AS cnt
FROM (
  SELECT
    d_year,
    i_category,
    COALESCE(catalog_profit, 0) + COALESCE(store_profit, 0) + COALESCE(web_profit, 0) - COALESCE(return_loss, 0) AS total_profit
  FROM joined
) sub
GROUP BY d_year, i_category
HAVING AVG(total_profit) > 1000
ORDER BY avg_profit DESC
LIMIT 100

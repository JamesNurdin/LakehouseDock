WITH store_agg AS (
  SELECT
    i.i_item_id,
    s.s_store_id AS source_id,
    d_sales.d_year AS d_year,
    ss.ss_quantity AS quantity,
    ss.ss_net_paid AS net_paid,
    ss.ss_net_profit AS net_profit,
    CASE WHEN ss.ss_net_profit > 0 THEN 'Profitable' ELSE 'Loss' END AS profit_flag,
    ib.ib_lower_bound AS income_lower
  FROM store_sales ss
  JOIN date_dim d_sales
    ON ss.ss_sold_date_sk = d_sales.d_date_sk
  JOIN item i
    ON ss.ss_item_sk = i.i_item_sk
  JOIN customer_demographics cd
    ON ss.ss_cdemo_sk = cd.cd_demo_sk
  JOIN household_demographics hd
    ON ss.ss_hdemo_sk = hd.hd_demo_sk
  JOIN income_band ib
    ON hd.hd_income_band_sk = ib.ib_income_band_sk
  JOIN customer_address ca
    ON ss.ss_addr_sk = ca.ca_address_sk
  JOIN store s
    ON ss.ss_store_sk = s.s_store_sk
  WHERE d_sales.d_year = 2001
    AND i.i_category = 'Sports'
    AND s.s_country = 'United States'
    AND ca.ca_state = 'CA'
    AND ib.ib_lower_bound >= 100000
    AND i.i_current_price BETWEEN 50 AND 200
),
web_agg AS (
  SELECT
    i.i_item_id,
    web.web_site_id AS source_id,
    d_sales.d_year AS d_year,
    ws.ws_quantity AS quantity,
    ws.ws_net_paid AS net_paid,
    ws.ws_net_profit AS net_profit,
    CASE WHEN ws.ws_net_profit > 0 THEN 'Profitable' ELSE 'Loss' END AS profit_flag,
    ib.ib_lower_bound AS income_lower
  FROM web_sales ws
  JOIN date_dim d_sales
    ON ws.ws_sold_date_sk = d_sales.d_date_sk
  JOIN item i
    ON ws.ws_item_sk = i.i_item_sk
  JOIN customer_demographics cd
    ON ws.ws_bill_cdemo_sk = cd.cd_demo_sk
  JOIN household_demographics hd
    ON ws.ws_bill_hdemo_sk = hd.hd_demo_sk
  JOIN income_band ib
    ON hd.hd_income_band_sk = ib.ib_income_band_sk
  JOIN customer_address ca
    ON ws.ws_bill_addr_sk = ca.ca_address_sk
  JOIN web_site web
    ON ws.ws_web_site_sk = web.web_site_sk
  WHERE d_sales.d_year = 2001
    AND i.i_category = 'Sports'
    AND web.web_market_manager = 'Jarvis Allen'
    AND ca.ca_state = 'CA'
    AND ib.ib_lower_bound >= 100000
    AND i.i_current_price BETWEEN 50 AND 200
),
combined AS (
  SELECT * FROM store_agg
  UNION ALL
  SELECT * FROM web_agg
)
SELECT
  combined.source_id,
  combined.d_year,
  COUNT(DISTINCT combined.i_item_id) AS distinct_items,
  SUM(combined.quantity) AS total_quantity,
  SUM(combined.net_paid) AS total_net_paid,
  AVG(combined.net_paid) AS avg_net_paid,
  MIN(combined.income_lower) AS min_income_lower,
  MAX(combined.income_lower) AS max_income_lower,
  SUM(CASE WHEN combined.profit_flag = 'Profitable' THEN 1 ELSE 0 END) AS profitable_count,
  (SELECT AVG(net_paid) FROM combined) AS overall_avg_net_paid
FROM combined
GROUP BY combined.source_id, combined.d_year
ORDER BY total_net_paid DESC
LIMIT 100

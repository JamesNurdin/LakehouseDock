WITH all_sales AS (
  SELECT
    'store' AS channel,
    ss_sold_date_sk AS sold_date_sk,
    ss_sold_time_sk AS sold_time_sk,
    ss_item_sk AS item_sk,
    ss_store_sk AS channel_entity_sk,
    ss_promo_sk AS promo_sk,
    ss_customer_sk AS customer_sk,
    ss_cdemo_sk AS cd_demo_sk,
    ss_hdemo_sk AS hd_demo_sk,
    ss_addr_sk AS addr_sk,
    ss_quantity AS quantity,
    ss_net_paid AS net_paid,
    ss_net_profit AS net_profit
  FROM store_sales
  UNION ALL
  SELECT
    'catalog' AS channel,
    cs_sold_date_sk,
    cs_sold_time_sk,
    cs_item_sk,
    cs_call_center_sk,
    cs_promo_sk,
    cs_bill_customer_sk,
    cs_bill_cdemo_sk,
    cs_bill_hdemo_sk,
    cs_ship_addr_sk,
    cs_quantity,
    cs_net_paid,
    cs_net_profit
  FROM catalog_sales
  UNION ALL
  SELECT
    'web' AS channel,
    ws_sold_date_sk,
    ws_sold_time_sk,
    ws_item_sk,
    ws_web_site_sk,
    ws_promo_sk,
    ws_bill_customer_sk,
    ws_bill_cdemo_sk,
    ws_bill_hdemo_sk,
    ws_ship_addr_sk,
    ws_quantity,
    ws_net_paid,
    ws_net_profit
  FROM web_sales
),
sales_joined AS (
  SELECT
    a.channel,
    d.d_year,
    d.d_moy AS month,
    d.d_quarter_name,
    t.t_hour,
    i.i_category,
    i.i_brand,
    p.p_promo_name,
    a.quantity,
    a.net_paid,
    a.net_profit,
    c.c_preferred_cust_flag,
    ca.ca_state,
    cd.cd_gender,
    hd.hd_income_band_sk,
    ib.ib_lower_bound,
    ib.ib_upper_bound,
    COALESCE(s.s_store_name, cc.cc_name, ws2.web_name) AS channel_entity_name
  FROM all_sales a
  JOIN date_dim d ON a.sold_date_sk = d.d_date_sk
  JOIN time_dim t ON a.sold_time_sk = t.t_time_sk
  JOIN item i ON a.item_sk = i.i_item_sk
  LEFT JOIN promotion p ON a.promo_sk = p.p_promo_sk
  LEFT JOIN customer c ON a.customer_sk = c.c_customer_sk
  LEFT JOIN customer_address ca ON a.addr_sk = ca.ca_address_sk
  LEFT JOIN customer_demographics cd ON a.cd_demo_sk = cd.cd_demo_sk
  LEFT JOIN household_demographics hd ON a.hd_demo_sk = hd.hd_demo_sk
  LEFT JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
  LEFT JOIN store s ON a.channel = 'store' AND a.channel_entity_sk = s.s_store_sk
  LEFT JOIN call_center cc ON a.channel = 'catalog' AND a.channel_entity_sk = cc.cc_call_center_sk
  LEFT JOIN web_site ws2 ON a.channel = 'web' AND a.channel_entity_sk = ws2.web_site_sk
),
agg AS (
  SELECT
    channel,
    d_year,
    month,
    i_category,
    i_brand,
    p_promo_name,
    cd_gender,
    ib_lower_bound,
    ib_upper_bound,
    SUM(quantity) AS total_quantity,
    SUM(net_paid) AS total_net_paid,
    SUM(net_profit) AS total_net_profit,
    AVG(CASE WHEN quantity > 0 THEN net_paid / quantity END) AS avg_price,
    COUNT(DISTINCT ca_state) AS distinct_states,
    COUNT(DISTINCT CASE WHEN c_preferred_cust_flag = 'Y' THEN c_preferred_cust_flag END) AS preferred_customer_cnt
  FROM sales_joined
  GROUP BY ROLLUP (channel, d_year, month, i_category, i_brand, cd_gender, ib_lower_bound, ib_upper_bound, p_promo_name)
  HAVING channel IS NOT NULL
)
SELECT
  channel,
  d_year,
  month,
  i_category,
  i_brand,
  cd_gender,
  CASE WHEN ib_lower_bound IS NOT NULL AND ib_upper_bound IS NOT NULL THEN concat(CAST(ib_lower_bound AS VARCHAR), '-', CAST(ib_upper_bound AS VARCHAR)) END AS income_bracket,
  COALESCE(p_promo_name, 'No Promotion') AS promo_name,
  total_quantity,
  total_net_paid,
  total_net_profit,
  avg_price,
  distinct_states,
  preferred_customer_cnt,
  total_net_profit / NULLIF(total_net_paid, 0) AS profit_margin,
  RANK() OVER (PARTITION BY channel, d_year, month ORDER BY total_net_profit DESC) AS profit_rank,
  SUM(total_net_profit) OVER (PARTITION BY channel ORDER BY d_year, month ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS cumulative_profit
FROM agg
WHERE d_year BETWEEN 1998 AND 2002
ORDER BY channel, d_year, month, profit_rank
LIMIT 200

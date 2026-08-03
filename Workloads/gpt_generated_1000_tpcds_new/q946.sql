WITH
cat_base AS (
  SELECT
    cs.cs_order_number,
    cs.cs_ext_sales_price,
    cs.cs_net_profit,
    i.i_category,
    ca.ca_state,
    cd.cd_gender,
    hd.hd_buy_potential,
    ib.ib_lower_bound,
    p.p_discount_active,
    sm.sm_type,
    td.t_hour
  FROM catalog_sales cs
  JOIN time_dim td ON cs.cs_sold_time_sk = td.t_time_sk
  JOIN item i ON cs.cs_item_sk = i.i_item_sk
  JOIN customer_address ca ON cs.cs_bill_addr_sk = ca.ca_address_sk
  JOIN customer_demographics cd ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
  JOIN household_demographics hd ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
  JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
  JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
  JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
  WHERE ca.ca_state = 'CA'
    AND cd.cd_gender = 'M'
    AND ib.ib_lower_bound >= 100000
    AND p.p_discount_active = 'Y'
),

ws_base AS (
  SELECT
    ws.ws_order_number,
    ws.ws_ext_sales_price,
    ws.ws_net_profit,
    i.i_category,
    ca.ca_state,
    cd.cd_gender,
    hd.hd_buy_potential,
    ib.ib_lower_bound,
    p.p_discount_active,
    sm.sm_type,
    td.t_hour,
    wp.wp_type,
    web.web_name
  FROM web_sales ws
  JOIN time_dim td ON ws.ws_sold_time_sk = td.t_time_sk
  JOIN item i ON ws.ws_item_sk = i.i_item_sk
  JOIN customer_address ca ON ws.ws_bill_addr_sk = ca.ca_address_sk
  JOIN customer_demographics cd ON ws.ws_bill_cdemo_sk = cd.cd_demo_sk
  JOIN household_demographics hd ON ws.ws_bill_hdemo_sk = hd.hd_demo_sk
  JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
  JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
  JOIN ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
  JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
  JOIN web_site web ON ws.ws_web_site_sk = web.web_site_sk
  WHERE wp.wp_type = 'content'
    AND web.web_country = 'United States'
    AND sm.sm_code = 'AIR'
    AND td.t_hour BETWEEN 9 AND 17
),

wr_base AS (
  SELECT
    wr.wr_return_quantity,
    wr.wr_return_amt,
    i.i_category,
    cd.cd_gender,
    hd.hd_buy_potential,
    ib.ib_lower_bound,
    rp.r_reason_desc,
    wp.wp_type,
    ws.ws_order_number
  FROM web_returns wr
  JOIN item i ON wr.wr_item_sk = i.i_item_sk
  JOIN customer_demographics cd ON wr.wr_refunded_cdemo_sk = cd.cd_demo_sk
  JOIN household_demographics hd ON wr.wr_refunded_hdemo_sk = hd.hd_demo_sk
  JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
  JOIN reason rp ON wr.wr_reason_sk = rp.r_reason_sk
  JOIN web_page wp ON wr.wr_web_page_sk = wp.wp_web_page_sk
  JOIN web_sales ws ON wr.wr_item_sk = ws.ws_item_sk AND wr.wr_order_number = ws.ws_order_number
  WHERE rp.r_reason_desc LIKE '%defect%'
    AND ib.ib_upper_bound <= 150000
),

agg_cat AS (
  SELECT i_category,
         SUM(cs_ext_sales_price) AS total_sales,
         COUNT(*) AS order_cnt
  FROM cat_base
  GROUP BY i_category
),

agg_ws AS (
  SELECT i_category,
         SUM(ws_ext_sales_price) AS total_sales,
         COUNT(*) AS order_cnt
  FROM ws_base
  GROUP BY i_category
),

union_agg AS (
  SELECT i_category, total_sales, order_cnt FROM agg_cat
  UNION
  SELECT i_category, total_sales, order_cnt FROM agg_ws
),

ranked AS (
  SELECT
    i_category,
    total_sales,
    order_cnt,
    ROW_NUMBER() OVER (PARTITION BY i_category ORDER BY total_sales DESC) AS rn
  FROM union_agg
),

cross_joined AS (
  SELECT ib.ib_income_band_sk, v.n
  FROM (SELECT ib_income_band_sk FROM income_band WHERE ib_lower_bound >= 120000) ib
  CROSS JOIN (VALUES (1), (2), (3)) AS v(n)
),

order_intersect AS (
  SELECT ws_order_number FROM web_sales
  INTERSECT
  SELECT wr_order_number FROM web_returns
),

full_outer AS (
  SELECT
    ss.ss_ticket_number,
    td.t_hour,
    ss.ss_ext_sales_price,
    ss.ss_net_profit
  FROM store_sales ss
  FULL OUTER JOIN time_dim td
    ON ss.ss_sold_time_sk = td.t_time_sk
  WHERE ss.ss_quantity > 5
)
SELECT
  r.i_category,
  r.total_sales,
  r.order_cnt,
  r.rn,
  cj.ib_income_band_sk,
  cj.n,
  oi.ws_order_number,
  fo.ss_ticket_number,
  fo.ss_ext_sales_price,
  fo.ss_net_profit
FROM ranked r
LEFT JOIN cross_joined cj ON 1 = 1
LEFT JOIN order_intersect oi ON 1 = 1
LEFT JOIN full_outer fo ON 1 = 1
LIMIT 100

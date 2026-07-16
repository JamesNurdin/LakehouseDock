WITH
store_agg AS (
  SELECT
    d.d_year,
    s.s_state AS state,
    SUM(ss.ss_net_paid) AS net_paid,
    SUM(ss.ss_net_profit) AS net_profit
  FROM store_sales ss
  JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
  JOIN store s ON ss.ss_store_sk = s.s_store_sk
  JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
  JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
  WHERE d.d_year BETWEEN 1999 AND 2001
    AND cd.cd_gender = 'M'
    AND s.s_state IS NOT NULL
  GROUP BY d.d_year, s.s_state
),
catalog_agg AS (
  SELECT
    d.d_year,
    cc.cc_state AS state,
    SUM(cs.cs_net_paid) AS net_paid,
    SUM(cs.cs_net_profit) AS net_profit
  FROM catalog_sales cs
  JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
  JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
  JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
  WHERE d.d_year BETWEEN 1999 AND 2001
    AND p.p_discount_active = 'Y'
    AND cc.cc_state IS NOT NULL
  GROUP BY d.d_year, cc.cc_state
),
web_agg AS (
  SELECT
    d.d_year,
    wp.wp_type AS state,
    SUM(ws.ws_net_paid) AS net_paid,
    SUM(ws.ws_net_profit) AS net_profit
  FROM web_sales ws
  JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
  JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
  JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
  WHERE d.d_year BETWEEN 1999 AND 2001
    AND p.p_discount_active = 'Y'
    AND wp.wp_type IS NOT NULL
  GROUP BY d.d_year, wp.wp_type
),
union_all_sales AS (
  SELECT d_year, state, net_paid, net_profit FROM store_agg
  UNION ALL
  SELECT d_year, state, net_paid, net_profit FROM catalog_agg
  UNION ALL
  SELECT d_year, state, net_paid, net_profit FROM web_agg
)
SELECT
  d_year,
  state,
  total_net_paid,
  total_net_profit,
  RANK() OVER (PARTITION BY d_year ORDER BY total_net_paid DESC) AS sales_rank
FROM (
  SELECT
    d_year,
    state,
    SUM(net_paid) AS total_net_paid,
    SUM(net_profit) AS total_net_profit
  FROM union_all_sales
  GROUP BY d_year, state
) agg
WHERE total_net_paid > 5000000
ORDER BY d_year, sales_rank
LIMIT 50

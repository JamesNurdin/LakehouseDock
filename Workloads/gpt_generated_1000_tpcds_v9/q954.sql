WITH base AS (
  SELECT
    c.c_customer_id,
    c.c_first_name,
    c.c_last_name,
    d.d_year,
    cs.cs_net_paid,
    cs.cs_net_profit,
    ss.ss_net_paid,
    ss.ss_net_profit,
    ws.ws_net_paid,
    ws.ws_net_profit,
    sm.sm_code,
    cd.cd_credit_rating,
    c.c_preferred_cust_flag,
    wp.wp_char_count,
    i.inv_quantity_on_hand,
    cc.cc_name,
    p.p_promo_name
  FROM catalog_sales cs
  JOIN date_dim d
    ON cs.cs_sold_date_sk = d.d_date_sk
  JOIN customer c
    ON cs.cs_bill_customer_sk = c.c_customer_sk
  JOIN customer_demographics cd
    ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
  JOIN customer_address ca
    ON cs.cs_bill_addr_sk = ca.ca_address_sk
  JOIN call_center cc
    ON cs.cs_call_center_sk = cc.cc_call_center_sk
  JOIN ship_mode sm
    ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
  JOIN promotion p
    ON cs.cs_promo_sk = p.p_promo_sk
  LEFT JOIN store_sales ss
    ON ss.ss_sold_date_sk = d.d_date_sk
   AND ss.ss_customer_sk = c.c_customer_sk
  LEFT JOIN web_sales ws
    ON ws.ws_sold_date_sk = d.d_date_sk
   AND ws.ws_bill_customer_sk = c.c_customer_sk
  LEFT JOIN web_page wp
    ON ws.ws_web_page_sk = wp.wp_web_page_sk
  LEFT JOIN web_site wsit
    ON ws.ws_web_site_sk = wsit.web_site_sk
  LEFT JOIN inventory i
    ON i.inv_date_sk = d.d_date_sk
  WHERE
    d.d_year = 2001
    AND sm.sm_code = 'AIR'
    AND cd.cd_credit_rating = 'Good'
    AND c.c_preferred_cust_flag = 'Y'
    AND wp.wp_char_count > 2000
),
agg AS (
  SELECT
    c_customer_id,
    c_first_name,
    c_last_name,
    d_year,
    SUM(COALESCE(cs_net_paid, 0) + COALESCE(ss_net_paid, 0) + COALESCE(ws_net_paid, 0)) AS total_net_paid,
    SUM(COALESCE(cs_net_profit, 0) + COALESCE(ss_net_profit, 0) + COALESCE(ws_net_profit, 0)) AS total_net_profit,
    COUNT(*) AS txn_count
  FROM base
  GROUP BY c_customer_id, c_first_name, c_last_name, d_year
)
SELECT
  c_customer_id,
  c_first_name,
  c_last_name,
  d_year,
  total_net_paid,
  total_net_profit,
  txn_count,
  RANK() OVER (ORDER BY total_net_paid DESC) AS sales_rank,
  SUM(total_net_paid) OVER (
    ORDER BY total_net_paid DESC
    ROWS BETWEEN 1 PRECEDING AND 1 FOLLOWING
  ) AS moving_total_net_paid
FROM agg
ORDER BY total_net_paid DESC
LIMIT 50

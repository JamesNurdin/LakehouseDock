WITH sales_agg AS (
  SELECT
    c.c_customer_id,
    c.c_first_name,
    c.c_last_name,
    cd.cd_gender,
    ca.ca_state,
    p.p_promo_name,
    cc.cc_name AS call_center_name,
    sm.sm_type AS ship_mode_type,
    wp.wp_url,
    i.inv_quantity_on_hand,
    SUM(ss.ss_net_paid) AS store_net_paid,
    SUM(ws.ws_net_paid) AS web_net_paid,
    SUM(cs.cs_net_paid) AS catalog_net_paid,
    COUNT(sr.sr_ticket_number) AS return_count
  FROM store_sales ss
  JOIN date_dim d
    ON ss.ss_sold_date_sk = d.d_date_sk
  JOIN customer c
    ON ss.ss_customer_sk = c.c_customer_sk
  JOIN customer_demographics cd
    ON ss.ss_cdemo_sk = cd.cd_demo_sk
  JOIN customer_address ca
    ON ss.ss_addr_sk = ca.ca_address_sk
  JOIN promotion p
    ON ss.ss_promo_sk = p.p_promo_sk
  LEFT JOIN store_returns sr
    ON sr.sr_ticket_number = ss.ss_ticket_number
  JOIN catalog_sales cs
    ON cs.cs_bill_customer_sk = c.c_customer_sk
  JOIN call_center cc
    ON cs.cs_call_center_sk = cc.cc_call_center_sk
  CROSS JOIN LATERAL (
        SELECT cp.cp_catalog_page_id, cp.cp_description
        FROM catalog_page cp
        WHERE cp.cp_catalog_page_sk = cs.cs_catalog_page_sk
        LIMIT 1
    ) cp_l
  JOIN ship_mode sm
    ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
  JOIN web_sales ws
    ON ws.ws_bill_customer_sk = c.c_customer_sk
  JOIN web_page wp
    ON ws.ws_web_page_sk = wp.wp_web_page_sk
  JOIN inventory i
    ON i.inv_date_sk = d.d_date_sk
  WHERE d.d_year = 2001
    AND ss.ss_quantity > 5
    AND p.p_discount_active = 'Y'
    AND sm.sm_type = 'AIR'
    AND i.inv_quantity_on_hand > 500
  GROUP BY
    c.c_customer_id,
    c.c_first_name,
    c.c_last_name,
    cd.cd_gender,
    ca.ca_state,
    p.p_promo_name,
    cc.cc_name,
    sm.sm_type,
    wp.wp_url,
    i.inv_quantity_on_hand
)
SELECT
  sa.c_customer_id,
  sa.c_first_name,
  sa.c_last_name,
  sa.cd_gender,
  sa.ca_state,
  sa.p_promo_name,
  sa.call_center_name,
  sa.ship_mode_type,
  sa.wp_url,
  sa.inv_quantity_on_hand,
  sa.store_net_paid,
  sa.web_net_paid,
  sa.catalog_net_paid,
  (sa.store_net_paid + sa.web_net_paid + sa.catalog_net_paid) AS total_net_paid,
  sa.return_count,
  ROW_NUMBER() OVER (PARTITION BY sa.cd_gender ORDER BY (sa.store_net_paid + sa.web_net_paid + sa.catalog_net_paid) DESC) AS gender_rank
FROM sales_agg sa
ORDER BY total_net_paid DESC
LIMIT 100

WITH
  agg_catalog AS (
    SELECT
      cs_bill_customer_sk AS cust_sk,
      cs_sold_time_sk   AS time_sk,
      cs_call_center_sk AS cc_sk,
      cs_catalog_page_sk AS cp_sk,
      cs_promo_sk       AS promo_sk,
      cs_ship_mode_sk   AS sm_sk,
      SUM(cs_net_paid)  AS total_net_paid,
      COUNT(*)          AS order_cnt
    FROM catalog_sales
    WHERE cs_quantity > 2
      AND cs_net_paid > 0
      AND cs_sold_time_sk IS NOT NULL
      AND cs_call_center_sk IS NOT NULL
      AND cs_ship_mode_sk IS NOT NULL
    GROUP BY
      cs_bill_customer_sk,
      cs_sold_time_sk,
      cs_call_center_sk,
      cs_catalog_page_sk,
      cs_promo_sk,
      cs_ship_mode_sk
  ),

  agg_web AS (
    SELECT
      ws_bill_customer_sk AS cust_sk,
      ws_sold_time_sk   AS time_sk,
      ws_ship_mode_sk   AS sm_sk,
      ws_promo_sk       AS promo_sk,
      ws_web_page_sk    AS wp_sk,
      SUM(ws_net_paid)  AS total_net_paid,
      COUNT(*)          AS order_cnt
    FROM web_sales
    WHERE ws_quantity > 2
      AND ws_net_paid > 0
      AND ws_sold_time_sk IS NOT NULL
    GROUP BY
      ws_bill_customer_sk,
      ws_sold_time_sk,
      ws_ship_mode_sk,
      ws_promo_sk,
      ws_web_page_sk
  )

SELECT *
FROM (
  SELECT
    c.c_customer_id,
    c.c_first_name,
    c.c_last_name,
    td.t_hour,
    cc.cc_name,
    cp.cp_department,
    p.p_promo_name,
    sm.sm_type,
    agg.total_net_paid,
    agg.order_cnt,
    RANK() OVER (PARTITION BY cp.cp_department ORDER BY agg.total_net_paid DESC) AS dept_rank,
    'Catalog' AS channel

  FROM agg_catalog agg
  JOIN customer c                     ON agg.cust_sk  = c.c_customer_sk
  JOIN time_dim td                     ON agg.time_sk  = td.t_time_sk
  JOIN call_center cc                  ON agg.cc_sk    = cc.cc_call_center_sk
  JOIN catalog_page cp                 ON agg.cp_sk    = cp.cp_catalog_page_sk
  JOIN promotion p                     ON agg.promo_sk = p.p_promo_sk
  JOIN ship_mode sm                    ON agg.sm_sk    = sm.sm_ship_mode_sk
  JOIN customer_demographics cd        ON c.c_current_cdemo_sk = cd.cd_demo_sk
  JOIN household_demographics hd       ON c.c_current_hdemo_sk = hd.hd_demo_sk
  WHERE cc.cc_tax_percentage > 0.05
    AND cc.cc_state = 'CA'
    AND cp.cp_type = 'Online'
    AND p.p_discount_active = 'Y'
    AND sm.sm_code = 'AIR'
    AND cd.cd_credit_rating = 'High Risk'
) 
UNION ALL
SELECT
  c.c_customer_id,
  c.c_first_name,
  c.c_last_name,
  td.t_hour,
  wp.wp_url,
  NULL AS cp_department,
  p.p_promo_name,
  sm.sm_type,
  agg.total_net_paid,
  agg.order_cnt,
  ROW_NUMBER() OVER (PARTITION BY wp.wp_type ORDER BY agg.total_net_paid DESC) AS url_rank,
  'Web' AS channel

FROM agg_web agg
JOIN customer c                     ON agg.cust_sk  = c.c_customer_sk
JOIN time_dim td                     ON agg.time_sk  = td.t_time_sk
JOIN ship_mode sm                    ON agg.sm_sk    = sm.sm_ship_mode_sk
JOIN promotion p                     ON agg.promo_sk = p.p_promo_sk
JOIN web_page wp                    ON agg.wp_sk    = wp.wp_web_page_sk
JOIN customer_demographics cd        ON c.c_current_cdemo_sk = cd.cd_demo_sk
JOIN household_demographics hd       ON c.c_current_hdemo_sk = hd.hd_demo_sk
WHERE wp.wp_type = 'Content'
  AND p.p_channel_email = 'Y'
  AND sm.sm_type = 'Standard'
  AND cd.cd_education_status = 'Advanced Degree'
  AND hd.hd_buy_potential = '5000-9999'
  AND td.t_hour BETWEEN 9 AND 17
ORDER BY total_net_paid DESC, channel
LIMIT 100

WITH
  store_sales_agg AS (
    SELECT
      ss_sold_date_sk,
      ss_customer_sk,
      SUM(ss_net_paid) AS total_net_paid,
      COUNT(*)        AS sales_cnt
    FROM store_sales
    WHERE ss_quantity > 5
    GROUP BY ss_sold_date_sk, ss_customer_sk
  ),
  sales_grouping AS (
    SELECT
      c.c_customer_sk,
      td.t_hour,
      SUM(ss.ss_ext_sales_price) AS ext_sales,
      GROUPING(c.c_customer_sk) AS g_cust,
      GROUPING(td.t_hour)      AS g_hour
    FROM store_sales ss
    JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
    JOIN time_dim td ON ss.ss_sold_time_sk = td.t_time_sk
    GROUP BY GROUPING SETS ( (c.c_customer_sk, td.t_hour), (c.c_customer_sk) )
  )
SELECT
  c.c_customer_id,
  ca.ca_city,
  CASE WHEN cd.cd_gender = 'M' THEN 'Male' ELSE 'Female' END AS gender_desc,
  ssag.total_net_paid,
  sg.ext_sales,
  p.p_promo_name,
  r.r_reason_desc,
  ws.ws_net_paid,
  ws.ws_coupon_amt,
  ROW_NUMBER() OVER (PARTITION BY ca.ca_city ORDER BY ssag.total_net_paid DESC) AS city_rank,
  LAG(ws.ws_net_paid) OVER (PARTITION BY ca.ca_city ORDER BY ssag.total_net_paid) AS prev_net_paid,
  promo_counts.promo_cnt
FROM store_sales_agg ssag
JOIN store_sales ss               ON ss.ss_sold_date_sk = ssag.ss_sold_date_sk
                                   AND ss.ss_customer_sk = ssag.ss_customer_sk
JOIN time_dim td                  ON ss.ss_sold_time_sk = td.t_time_sk
JOIN customer c                   ON ss.ss_customer_sk = c.c_customer_sk
JOIN customer_address ca          ON c.c_current_addr_sk = ca.ca_address_sk
JOIN customer_demographics cd    ON c.c_current_cdemo_sk = cd.cd_demo_sk
JOIN promotion p                  ON ss.ss_promo_sk = p.p_promo_sk
JOIN store_returns sr             ON ss.ss_ticket_number = sr.sr_ticket_number
JOIN reason r                     ON sr.sr_reason_sk = r.r_reason_sk
JOIN catalog_sales cs             ON cs.cs_bill_customer_sk = c.c_customer_sk
JOIN call_center cc               ON cs.cs_call_center_sk = cc.cc_call_center_sk
JOIN catalog_page cp              ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
JOIN catalog_returns cr           ON cr.cr_order_number = cs.cs_order_number
JOIN web_sales ws                 ON ws.ws_bill_customer_sk = c.c_customer_sk
JOIN web_page wp                  ON ws.ws_web_page_sk = wp.wp_web_page_sk
JOIN web_site wsite               ON ws.ws_web_site_sk = wsite.web_site_sk
JOIN sales_grouping sg            ON sg.c_customer_sk = c.c_customer_sk
LEFT JOIN LATERAL (
  SELECT COUNT(*) AS promo_cnt
  FROM promotion p2
  WHERE p2.p_promo_sk = ss.ss_promo_sk
) AS promo_counts(promo_cnt) ON TRUE
WHERE ca.ca_city IN ('Pleasant Valley', 'New Hope', 'Maple Grove', 'Martinsville')
  AND td.t_hour BETWEEN 9 AND 17
  AND ws.ws_coupon_amt > 100
  AND p.p_discount_active = 'Y'
ORDER BY ssag.total_net_paid DESC
OFFSET 0 ROWS FETCH NEXT 100 ROWS ONLY

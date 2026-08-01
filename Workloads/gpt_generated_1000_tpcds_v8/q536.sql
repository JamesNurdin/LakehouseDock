WITH
  agg_cs AS (
    SELECT cs_order_number,
           SUM(cs_net_paid) AS total_cs_net_paid
    FROM catalog_sales
    GROUP BY cs_order_number
  ),
  sample_ca AS (
    SELECT ca_address_sk,
           ca_city
    FROM customer_address
    TABLESAMPLE BERNOULLI (10)
  )
SELECT *
FROM (
  SELECT
    cs.cs_order_number                               AS order_number,
    agg.total_cs_net_paid,
    COALESCE(cr.cr_return_amount, wr.wr_return_amt) AS return_amount,
    s.s_store_name                                   AS store_name,
    wp.wp_url                                        AS web_page_url,
    r.r_reason_desc,
    r.r_reason_sk,
    sr.sr_return_quantity,
    ws.ws_quantity
  FROM store_returns sr
  JOIN time_dim td ON sr.sr_return_time_sk = td.t_time_sk
  JOIN customer c ON sr.sr_customer_sk = c.c_customer_sk
  JOIN customer_address ca ON sr.sr_addr_sk = ca.ca_address_sk
  JOIN sample_ca sca ON ca.ca_address_sk = sca.ca_address_sk
  JOIN household_demographics hd ON sr.sr_hdemo_sk = hd.hd_demo_sk
  JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
  FULL OUTER JOIN store s ON sr.sr_store_sk = s.s_store_sk
  LEFT JOIN catalog_sales cs ON cs.cs_bill_customer_sk = c.c_customer_sk
                               AND cs.cs_sold_time_sk = td.t_time_sk
  LEFT JOIN agg_cs agg ON cs.cs_order_number = agg.cs_order_number
  LEFT JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
  LEFT JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
  LEFT JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
  LEFT JOIN catalog_returns cr ON cr.cr_order_number = cs.cs_order_number
                                AND cr.cr_returned_time_sk = td.t_time_sk
  LEFT JOIN web_sales ws ON ws.ws_bill_customer_sk = c.c_customer_sk
                           AND ws.ws_sold_time_sk = td.t_time_sk
  LEFT JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
  LEFT JOIN web_returns wr ON wr.wr_order_number = ws.ws_order_number
                             AND wr.wr_returned_time_sk = td.t_time_sk
  WHERE c.c_birth_year = 1970
    AND ca.ca_street_type = 'Drive'
    AND s.s_state = 'CA'
    AND td.t_hour BETWEEN 9 AND 17

  UNION DISTINCT

  SELECT
    ws.ws_order_number                               AS order_number,
    agg.total_cs_net_paid,
    wr.wr_return_amt                                AS return_amount,
    NULL                                            AS store_name,
    wp.wp_url                                        AS web_page_url,
    r2.r_reason_desc,
    r2.r_reason_sk,
    NULL                                            AS sr_return_quantity,
    ws.ws_quantity
  FROM web_returns wr
  JOIN time_dim td ON wr.wr_returned_time_sk = td.t_time_sk
  JOIN customer c ON wr.wr_refunded_customer_sk = c.c_customer_sk
  JOIN customer_address ca ON wr.wr_refunded_addr_sk = ca.ca_address_sk
  JOIN sample_ca sca ON ca.ca_address_sk = sca.ca_address_sk
  JOIN household_demographics hd ON wr.wr_refunded_hdemo_sk = hd.hd_demo_sk
  JOIN reason r2 ON wr.wr_reason_sk = r2.r_reason_sk
  LEFT JOIN web_sales ws ON wr.wr_order_number = ws.ws_order_number
  LEFT JOIN agg_cs agg ON ws.ws_order_number = agg.cs_order_number
  LEFT JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
  WHERE c.c_birth_month = 5
    AND ca.ca_city = 'Chicago'
    AND td.t_hour BETWEEN 12 AND 20
    AND r2.r_reason_sk NOT IN (
          SELECT r3.r_reason_sk FROM reason r3 WHERE r3.r_reason_desc LIKE '%size%')
) AS combined
WHERE NOT EXISTS (
        SELECT 1
        FROM reason r_ex
        WHERE r_ex.r_reason_sk = combined.r_reason_sk
          AND r_ex.r_reason_desc = 'Wrong size'
      )
EXCEPT
SELECT order_number,
       total_cs_net_paid,
       return_amount,
       store_name,
       web_page_url,
       r_reason_desc,
       r_reason_sk,
       sr_return_quantity,
       ws_quantity
FROM (
  SELECT
    cs.cs_order_number                               AS order_number,
    agg.total_cs_net_paid,
    cr.cr_return_amount                             AS return_amount,
    s.s_store_name                                   AS store_name,
    wp.wp_url                                        AS web_page_url,
    r.r_reason_desc,
    r.r_reason_sk,
    sr.sr_return_quantity,
    ws.ws_quantity
  FROM store_returns sr
  JOIN time_dim td ON sr.sr_return_time_sk = td.t_time_sk
  JOIN customer c ON sr.sr_customer_sk = c.c_customer_sk
  JOIN store s ON sr.sr_store_sk = s.s_store_sk
  JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
  LEFT JOIN catalog_sales cs ON cs.cs_bill_customer_sk = c.c_customer_sk
  LEFT JOIN agg_cs agg ON cs.cs_order_number = agg.cs_order_number
  LEFT JOIN catalog_returns cr ON cr.cr_order_number = cs.cs_order_number
  LEFT JOIN web_sales ws ON ws.ws_bill_customer_sk = c.c_customer_sk
  LEFT JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
  WHERE agg.total_cs_net_paid < 500
) AS exclude_set
ORDER BY total_cs_net_paid DESC
OFFSET 10
LIMIT 100

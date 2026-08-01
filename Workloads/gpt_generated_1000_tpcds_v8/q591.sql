WITH
  sampled_catalog AS (
    SELECT cs.*
    FROM catalog_sales cs
    TABLESAMPLE BERNOULLI (10)
  ),
  joined_data AS (
    SELECT
      cs.cs_sold_date_sk,
      d.d_year,
      cs.cs_net_paid,
      cs.cs_quantity,
      cs.cs_item_sk,
      c.c_customer_id,
      ca.ca_zip,
      cd.cd_gender,
      p.p_promo_name,
      sm.sm_type,
      cc.cc_name,
      cp.cp_catalog_number,
      ws.ws_order_number,
      ws.ws_net_paid AS ws_net_paid,
      wr.wr_return_quantity,
      sr.sr_return_quantity,
      CASE
        WHEN cs.cs_net_paid > 1000 THEN 'HIGH'
        WHEN cs.cs_net_paid BETWEEN 500 AND 1000 THEN 'MEDIUM'
        ELSE 'LOW'
      END AS revenue_bucket,
      c.c_customer_sk
    FROM sampled_catalog cs
    JOIN date_dim d               ON cs.cs_sold_date_sk      = d.d_date_sk
    JOIN customer c               ON cs.cs_bill_customer_sk = c.c_customer_sk
    JOIN customer_address ca      ON cs.cs_bill_addr_sk      = ca.ca_address_sk
    JOIN customer_demographics cd ON cs.cs_bill_cdemo_sk    = cd.cd_demo_sk
    JOIN promotion p              ON cs.cs_promo_sk          = p.p_promo_sk
    JOIN ship_mode sm             ON cs.cs_ship_mode_sk      = sm.sm_ship_mode_sk
    JOIN call_center cc           ON cs.cs_call_center_sk    = cc.cc_call_center_sk
    JOIN catalog_page cp          ON cs.cs_catalog_page_sk   = cp.cp_catalog_page_sk
    LEFT JOIN web_sales ws        ON cs.cs_order_number      = ws.ws_order_number
    LEFT JOIN web_returns wr      ON ws.ws_order_number      = wr.wr_order_number
    LEFT JOIN store_returns sr    ON c.c_customer_sk          = sr.sr_customer_sk
    LEFT JOIN store s             ON sr.sr_store_sk           = s.s_store_sk
    LEFT JOIN reason r            ON sr.sr_reason_sk          = r.r_reason_sk
    LEFT JOIN time_dim t          ON cs.cs_sold_time_sk      = t.t_time_sk
    LEFT JOIN web_page wp         ON ws.ws_web_page_sk       = wp.wp_web_page_sk
    WHERE d.d_year = 2001
      AND ca.ca_location_type = 'apartment'
      AND sm.sm_type = 'AIR'
  ),
  store_dates AS (
    SELECT s.*, d.d_date_sk AS d_date_sk_sd
    FROM store s
    JOIN date_dim d ON s.s_closed_date_sk = d.d_date_sk
  ),
  call_center_dates AS (
    SELECT cc.*, d.d_date_sk AS d_date_sk_cc
    FROM call_center cc
    JOIN date_dim d ON cc.cc_closed_date_sk = d.d_date_sk
  ),
  full_joined AS (
    SELECT *
    FROM store_dates sd
    FULL OUTER JOIN call_center_dates cd ON sd.d_date_sk_sd = cd.d_date_sk_cc
  ),
  final_union AS (
    SELECT
      jd.d_year,
      jd.c_customer_id,
      jd.revenue_bucket,
      jd.cs_net_paid,
      ROW_NUMBER() OVER (PARTITION BY jd.c_customer_id ORDER BY jd.cs_net_paid DESC) AS rn,
      LAG(jd.cs_net_paid) OVER (PARTITION BY jd.c_customer_id ORDER BY jd.cs_net_paid DESC) AS prev_net_paid,
      (SELECT COUNT(*) FROM store_returns sr2 WHERE sr2.sr_customer_sk = jd.c_customer_sk) AS total_store_returns
    FROM joined_data jd
    UNION DISTINCT
    SELECT
      d.d_year,
      c.c_customer_id,
      CASE WHEN ws.ws_net_paid > 2000 THEN 'HIGH' ELSE 'LOW' END AS revenue_bucket,
      ws.ws_net_paid,
      ROW_NUMBER() OVER (PARTITION BY c.c_customer_id ORDER BY ws.ws_net_paid DESC) AS rn,
      LAG(ws.ws_net_paid) OVER (PARTITION BY c.c_customer_id ORDER BY ws.ws_net_paid DESC) AS prev_net_paid,
      (SELECT COUNT(*) FROM web_returns wr2 WHERE wr2.wr_refunded_customer_sk = c.c_customer_sk) AS total_store_returns
    FROM web_sales ws
    JOIN date_dim d   ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN customer c   ON ws.ws_bill_customer_sk = c.c_customer_sk
    WHERE d.d_year = 2001
      AND ws.ws_quantity > 5
      AND ws.ws_ship_mode_sk = (
            SELECT sm_ship_mode_sk
            FROM ship_mode
            WHERE sm_type = 'AIR'
            LIMIT 1
          )
  )
SELECT
  fu.d_year,
  fu.c_customer_id,
  fu.revenue_bucket,
  fu.cs_net_paid,
  fu.rn,
  fu.prev_net_paid,
  fu.total_store_returns
FROM final_union fu
ORDER BY fu.d_year DESC, fu.cs_net_paid DESC
OFFSET 0 FETCH FIRST 100 ROWS ONLY

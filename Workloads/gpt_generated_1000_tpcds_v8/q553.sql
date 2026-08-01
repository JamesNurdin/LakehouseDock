WITH
  -- Chain starting from catalog_sales and pulling in all required dimensions
  catalog_chain AS (
    SELECT
      cs.cs_order_number,
      cs.cs_sold_date_sk           AS sold_date_sk,
      d.d_year,
      c.c_customer_sk,
      c.c_first_name,
      c.c_last_name,
      cd.cd_gender,
      hd.hd_income_band_sk,
      cs.cs_net_paid,
      cs.cs_net_profit,
      cc.cc_name,
      sm.sm_type,
      w.w_warehouse_name,
      p.p_promo_name,
      r.r_reason_desc,
      cs.cs_quantity
    FROM catalog_sales cs
    JOIN date_dim d          ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN time_dim t          ON cs.cs_sold_time_sk = t.t_time_sk
    JOIN customer c          ON cs.cs_bill_customer_sk = c.c_customer_sk
    JOIN customer_demographics cd ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
    JOIN call_center cc      ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN ship_mode sm        ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN warehouse w         ON cs.cs_warehouse_sk = w.w_warehouse_sk
    JOIN promotion p         ON cs.cs_promo_sk = p.p_promo_sk
    LEFT JOIN store_returns sr ON sr.sr_customer_sk = c.c_customer_sk
    LEFT JOIN reason r        ON sr.sr_reason_sk = r.r_reason_sk
    WHERE d.d_year = 2001
      AND cd.cd_gender = 'M'
      AND p.p_promo_name = 'PROMO_001'
  ),

  -- Chain starting from web_sales and pulling in all required dimensions
  web_chain AS (
    SELECT
      ws.ws_order_number,
      ws.ws_sold_date_sk           AS sold_date_sk,
      d2.d_year,
      c.c_customer_sk,
      cd.cd_gender,
      hd.hd_income_band_sk,
      ws.ws_net_paid,
      ws.ws_net_profit,
      wp.wp_type,
      ws.ws_quantity,
      ws.ws_ext_sales_price
    FROM web_sales ws
    JOIN date_dim d2          ON ws.ws_sold_date_sk = d2.d_date_sk
    JOIN time_dim t2          ON ws.ws_sold_time_sk = t2.t_time_sk
    JOIN customer c          ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN customer_demographics cd ON ws.ws_bill_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd ON ws.ws_bill_hdemo_sk = hd.hd_demo_sk
    JOIN web_page wp          ON ws.ws_web_page_sk = wp.wp_web_page_sk
    LEFT JOIN web_returns wr ON wr.wr_order_number = ws.ws_order_number
    WHERE d2.d_year = 2001
      AND cd.cd_gender = 'M'
      AND wp.wp_type = 'content'
  ),

  -- Union of aggregated sales from both chains (distinct union)
  sales_union AS (
    SELECT
      c_customer_sk,
      sold_date_sk,
      SUM(cs_net_paid)   AS total_paid,
      SUM(cs_net_profit) AS total_profit,
      COUNT(*)           AS txn_cnt
    FROM catalog_chain
    GROUP BY c_customer_sk, sold_date_sk
    UNION
    SELECT
      c_customer_sk,
      sold_date_sk,
      SUM(ws_net_paid)   AS total_paid,
      SUM(ws_net_profit) AS total_profit,
      COUNT(*)           AS txn_cnt
    FROM web_chain
    GROUP BY c_customer_sk, sold_date_sk
  ),

  -- Customers that appear in both catalog and web sales (INTERSECT)
  common_customers AS (
    SELECT c_customer_sk FROM catalog_chain
    INTERSECT
    SELECT c_customer_sk FROM web_chain
  ),

  -- Final aggregation with ROLLUP and a window function
  final_agg AS (
    SELECT
      c_customer_sk,
      sold_date_sk,
      SUM(total_paid)            AS sum_paid,
      AVG(total_paid)            AS avg_paid,
      MIN(total_paid)            AS min_paid,
      MAX(total_paid)            AS max_paid,
      COUNT(*)                   AS num_customers,
      ROW_NUMBER() OVER (PARTITION BY c_customer_sk ORDER BY SUM(total_paid) DESC) AS rn
    FROM sales_union
    WHERE c_customer_sk IN (SELECT c_customer_sk FROM common_customers)
    GROUP BY ROLLUP (c_customer_sk, sold_date_sk)
  )
SELECT
  final_agg.c_customer_sk,
  final_agg.sold_date_sk,
  final_agg.sum_paid,
  final_agg.avg_paid,
  final_agg.min_paid,
  final_agg.max_paid,
  final_agg.num_customers,
  final_agg.rn,
  wsit.web_site_id,
  (SELECT AVG(cs_net_profit) FROM catalog_sales) AS avg_catalog_profit
FROM final_agg
RIGHT OUTER JOIN web_site wsit
  ON final_agg.sold_date_sk = wsit.web_open_date_sk
ORDER BY final_agg.sum_paid DESC
LIMIT 100

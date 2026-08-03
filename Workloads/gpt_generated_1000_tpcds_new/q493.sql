WITH
  -- Aggregate catalog sales with all necessary foreign keys
  catalog_agg AS (
    SELECT
      cs_catalog_page_sk,
      cs_call_center_sk,
      cs_ship_mode_sk,
      cs_sold_date_sk,
      cs_sold_time_sk,
      cs_bill_customer_sk,
      cs_bill_cdemo_sk,
      cs_bill_hdemo_sk,
      SUM(cs_net_profit) AS total_profit,
      COUNT(*) AS cnt
    FROM catalog_sales
    GROUP BY
      cs_catalog_page_sk,
      cs_call_center_sk,
      cs_ship_mode_sk,
      cs_sold_date_sk,
      cs_sold_time_sk,
      cs_bill_customer_sk,
      cs_bill_cdemo_sk,
      cs_bill_hdemo_sk
  ),
  -- Aggregate web sales with all necessary foreign keys
  web_agg AS (
    SELECT
      ws_order_number,
      ws_sold_date_sk,
      ws_sold_time_sk,
      ws_ship_mode_sk,
      ws_web_page_sk,
      ws_bill_customer_sk,
      ws_bill_cdemo_sk,
      ws_bill_hdemo_sk,
      SUM(ws_net_profit) AS ws_profit,
      COUNT(*) AS cnt
    FROM web_sales
    GROUP BY
      ws_order_number,
      ws_sold_date_sk,
      ws_sold_time_sk,
      ws_ship_mode_sk,
      ws_web_page_sk,
      ws_bill_customer_sk,
      ws_bill_cdemo_sk,
      ws_bill_hdemo_sk
  ),
  -- Scalar sub‑query that returns a single average profit value
  avg_profit AS (
    SELECT AVG(total_profit) AS avg_total_profit FROM catalog_agg
  ),
  -- First branch: catalog side
  cat_branch AS (
    SELECT
      ca.cs_catalog_page_sk        AS key_id,
      CASE WHEN ca.total_profit > (SELECT avg_total_profit FROM avg_profit)
           THEN 'Above Avg' ELSE 'Below Avg' END AS profit_category,
      ca.total_profit              AS profit,
      ROW_NUMBER() OVER (PARTITION BY cp.cp_type ORDER BY ca.total_profit DESC) AS rn
    FROM catalog_agg ca
    JOIN catalog_page cp          ON ca.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN call_center cc           ON ca.cs_call_center_sk = cc.cc_call_center_sk
    JOIN ship_mode sm             ON ca.cs_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN date_dim d_sold          ON ca.cs_sold_date_sk = d_sold.d_date_sk
    JOIN time_dim t               ON ca.cs_sold_time_sk = t.t_time_sk
    JOIN customer c               ON ca.cs_bill_customer_sk = c.c_customer_sk
    JOIN customer_demographics cd ON ca.cs_bill_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd ON ca.cs_bill_hdemo_sk = hd.hd_demo_sk
    JOIN store s                  ON s.s_closed_date_sk = d_sold.d_date_sk
    WHERE cp.cp_type = 'monthly'
      AND d_sold.d_year = 2001
      AND cc.cc_state = 'CA'
      AND sm.sm_type = 'AIR'
      AND t.t_hour BETWEEN 8 AND 17
      AND cd.cd_gender = 'M'
      AND hd.hd_buy_potential = 'HIGH'
      AND s.s_state = 'CA'
  ),
  -- Second branch: web side (includes returns and reason)
  web_branch AS (
    SELECT
      wa.ws_order_number           AS key_id,
      CASE WHEN wa.ws_profit > (SELECT avg_total_profit FROM avg_profit)
           THEN 'Above Avg' ELSE 'Below Avg' END AS profit_category,
      wa.ws_profit                 AS profit,
      ROW_NUMBER() OVER (PARTITION BY wp.wp_type ORDER BY wa.ws_profit DESC) AS rn
    FROM web_agg wa
    JOIN date_dim d_sold          ON wa.ws_sold_date_sk = d_sold.d_date_sk
    JOIN time_dim t               ON wa.ws_sold_time_sk = t.t_time_sk
    JOIN ship_mode sm             ON wa.ws_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN web_page wp              ON wa.ws_web_page_sk = wp.wp_web_page_sk
    JOIN customer c               ON wa.ws_bill_customer_sk = c.c_customer_sk
    JOIN customer_demographics cd ON wa.ws_bill_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd ON wa.ws_bill_hdemo_sk = hd.hd_demo_sk
    JOIN web_returns wr           ON wr.wr_order_number = wa.ws_order_number
    JOIN reason r                 ON wr.wr_reason_sk = r.r_reason_sk
    WHERE d_sold.d_moy = 11
      AND sm.sm_type = 'AIR'
      AND wp.wp_type = 'content'
      AND c.c_preferred_cust_flag = 'Y'
      AND t.t_hour BETWEEN 9 AND 18
      AND cd.cd_education_status = 'College'
      AND hd.hd_vehicle_count >= 2
      AND r.r_reason_id = 'AAAAAAAA'
  ),
  -- Union of the two branches (distinct by default)
  union_set AS (
    SELECT * FROM cat_branch
    UNION
    SELECT * FROM web_branch
  ),
  -- Remove rows that are classified as Below Avg
  after_except AS (
    SELECT * FROM union_set
    EXCEPT
    SELECT * FROM union_set WHERE profit_category = 'Below Avg'
  )
-- Final result: intersect rows that are in the top‑5 of their partition
SELECT key_id, profit_category, profit, rn
FROM after_except
INTERSECT
SELECT key_id, profit_category, profit, rn
FROM after_except
WHERE rn <= 5
ORDER BY profit DESC
LIMIT 100

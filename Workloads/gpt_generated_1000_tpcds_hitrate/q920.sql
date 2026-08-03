WITH
  inv_agg AS (
    SELECT
      inv_item_sk,
      inv_date_sk,
      SUM(inv_quantity_on_hand) AS total_qty
    FROM inventory
    WHERE inv_date_sk BETWEEN 2450800 AND 2450900
    GROUP BY inv_item_sk, inv_date_sk
  ),
  customer_demo AS (
    SELECT cd_demo_sk, cd_gender, cd_credit_rating
    FROM customer_demographics
    WHERE cd_credit_rating = 'Excellent'
  ),
  base AS (
    SELECT
      cs.cs_order_number,
      cs.cs_sold_date_sk,
      d.d_year,
      i.i_item_id,
      i.i_brand,
      sm.sm_type,
      cs.cs_net_profit,
      c.c_customer_sk,
      cd.cd_demo_sk,
      ss.ss_ticket_number,
      ws.ws_order_number,
      cp.cp_department,
      t.t_hour,
      -- correlated scalar subqueries
      (SELECT SUM(ws2.ws_net_paid)
         FROM web_sales ws2
        WHERE ws2.ws_bill_customer_sk = cs.cs_bill_customer_sk) AS total_ws_paid_by_customer,
      (SELECT MAX(ss2.ss_net_paid)
         FROM store_sales ss2
        WHERE ss2.ss_customer_sk = cs.cs_bill_customer_sk) AS max_store_paid,
      -- compare to an uncorrelated scalar subquery
      CASE WHEN cs.cs_sold_date_sk > (
               SELECT MIN(d2.d_date_sk)
                 FROM date_dim d2
                WHERE d2.d_year = 2000)
           THEN 'After2000'
           ELSE 'Before2000'
      END AS period_flag
    FROM catalog_sales cs
    JOIN catalog_page cp
      ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN ship_mode sm
      ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN item i
      ON cs.cs_item_sk = i.i_item_sk
    JOIN date_dim d
      ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN time_dim t
      ON cs.cs_sold_time_sk = t.t_time_sk
    JOIN customer c
      ON cs.cs_bill_customer_sk = c.c_customer_sk
    JOIN customer_demo cd
      ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN inv_agg ia
      ON i.i_item_sk = ia.inv_item_sk
     AND d.d_date_sk = ia.inv_date_sk
    LEFT JOIN catalog_returns cr
      ON cr.cr_order_number = cs.cs_order_number
    LEFT JOIN reason r
      ON cr.cr_reason_sk = r.r_reason_sk
    LEFT JOIN store_sales ss
      ON ss.ss_item_sk = cs.cs_item_sk
    LEFT JOIN store_returns sr
      ON sr.sr_ticket_number = ss.ss_ticket_number
    LEFT JOIN web_sales ws
      ON ws.ws_item_sk = cs.cs_item_sk
    LEFT JOIN web_returns wr
      ON wr.wr_order_number = ws.ws_order_number
    LEFT JOIN web_page wp
      ON ws.ws_web_page_sk = wp.wp_web_page_sk
    CROSS JOIN (VALUES (1), (2), (3)) AS seq(k)   -- small dimension cross‑joined with a computed set
    WHERE d.d_year = 2001
      AND i.i_brand = 'Brand#12'
      AND sm.sm_type = 'AIR'
      AND t.t_hour BETWEEN 8 AND 12
      AND cp.cp_department = 'Furniture'
      AND cs.cs_net_profit > 0
  )
SELECT
  sub.cs_order_number,
  sub.cs_sold_date_sk,
  sub.d_year,
  sub.i_item_id,
  sub.i_brand,
  sub.sm_type,
  sub.cs_net_profit,
  sub.c_customer_sk,
  sub.cd_demo_sk,
  sub.total_ws_paid_by_customer,
  sub.max_store_paid,
  sub.period_flag
FROM (
  SELECT
    b.*, 
    ROW_NUMBER() OVER (PARTITION BY b.i_item_id ORDER BY b.cs_net_profit DESC) AS rn
  FROM base b
  WHERE b.cs_order_number NOT IN (
          SELECT cr2.cr_order_number
            FROM catalog_returns cr2
           WHERE cr2.cr_return_amount > 1000)
) sub
WHERE sub.rn <= 3
ORDER BY sub.cs_net_profit DESC
LIMIT 100

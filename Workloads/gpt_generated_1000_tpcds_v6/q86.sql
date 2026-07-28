WITH
  sales_union AS (
    SELECT
      cs.cs_sold_date_sk AS date_sk,
      cs.cs_net_profit   AS profit,
      cs.cs_bill_customer_sk AS cust_sk,
      cs.cs_promo_sk     AS promo_sk
    FROM catalog_sales cs
    UNION ALL
    SELECT
      ws.ws_sold_date_sk AS date_sk,
      ws.ws_net_profit   AS profit,
      ws.ws_bill_customer_sk AS cust_sk,
      ws.ws_promo_sk     AS promo_sk
    FROM web_sales ws
  ),
  profit_agg AS (
    SELECT
      d.d_year,
      c.c_customer_id,
      ib.ib_lower_bound,
      SUM(su.profit)               AS sum_union_profit,
      SUM(ss.ss_net_profit)        AS sum_store_profit,
      SUM(ws.ws_net_profit)        AS sum_web_profit,
      CASE WHEN ib.ib_lower_bound > 40000 THEN 'High' ELSE 'Low' END AS income_category
    FROM sales_union su
    JOIN date_dim d      ON su.date_sk = d.d_date_sk
    JOIN customer c      ON su.cust_sk = c.c_customer_sk
    JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    JOIN household_demographics hd ON c.c_current_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib  ON hd.hd_income_band_sk = ib.ib_income_band_sk
    JOIN promotion p     ON su.promo_sk = p.p_promo_sk
    JOIN call_center cc  ON cc.cc_open_date_sk = d.d_date_sk
    JOIN web_sales ws    ON ws.ws_sold_date_sk = d.d_date_sk
                           AND ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN warehouse w     ON ws.ws_warehouse_sk = w.w_warehouse_sk
    JOIN inventory inv   ON inv.inv_date_sk = d.d_date_sk
                           AND inv.inv_warehouse_sk = w.w_warehouse_sk
    JOIN store_sales ss  ON ss.ss_sold_date_sk = d.d_date_sk
                           AND ss.ss_customer_sk = c.c_customer_sk
    JOIN time_dim td     ON ss.ss_sold_time_sk = td.t_time_sk
    JOIN web_returns wr ON wr.wr_order_number = ws.ws_order_number
                           AND wr.wr_returned_date_sk = d.d_date_sk
    WHERE d.d_year = 2001
      AND ca.ca_state = 'CA'
      AND ib.ib_upper_bound > 50000
      AND p.p_discount_active = 'Y'
      AND hd.hd_vehicle_count >= 2
      AND EXISTS (
            SELECT 1
            FROM household_demographics hd2
            WHERE hd2.hd_demo_sk = c.c_current_hdemo_sk
              AND hd2.hd_income_band_sk = ib.ib_income_band_sk
              AND hd2.hd_vehicle_count > 3
          )
    GROUP BY
      d.d_year,
      c.c_customer_id,
      ib.ib_lower_bound,
      CASE WHEN ib.ib_lower_bound > 40000 THEN 'High' ELSE 'Low' END
  )
SELECT
  d_year,
  c_customer_id,
  (sum_union_profit + sum_store_profit + sum_web_profit) AS total_profit,
  ROW_NUMBER() OVER (PARTITION BY d_year ORDER BY (sum_union_profit + sum_store_profit + sum_web_profit) DESC) AS profit_rank,
  income_category
FROM profit_agg
ORDER BY total_profit DESC
LIMIT 100

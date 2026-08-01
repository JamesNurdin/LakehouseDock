WITH
  inv_agg AS (
    SELECT
      inv_item_sk,
      inv_warehouse_sk,
      SUM(inv_quantity_on_hand) AS total_qty
    FROM inventory
    WHERE inv_date_sk IN (
      SELECT d_date_sk
      FROM date_dim
      WHERE d_year = 2001
        AND d_month_seq BETWEEN 120 AND 130
    )
    GROUP BY inv_item_sk, inv_warehouse_sk
  ),
  ss_agg AS (
    SELECT
      ss_item_sk,
      ss_store_sk,
      SUM(ss_net_paid) AS store_net_paid
    FROM store_sales
    WHERE ss_sold_date_sk IN (
      SELECT d_date_sk
      FROM date_dim
      WHERE d_year = 2001
        AND d_month_seq BETWEEN 1 AND 12
    )
    GROUP BY ss_item_sk, ss_store_sk
  ),
  union_returns AS (
    SELECT sr.sr_customer_sk AS cust_sk, sr.sr_return_amt AS ret_amt
    FROM store_returns sr
    WHERE sr.sr_return_quantity > 0
    UNION
    SELECT wr.wr_refunded_customer_sk AS cust_sk, wr.wr_return_amt AS ret_amt
    FROM web_returns wr
    WHERE wr.wr_return_quantity > 0
  ),
  store_branch AS (
    SELECT
      c.c_customer_sk,
      c.c_first_name,
      c.c_last_name,
      ca.ca_city,
      hd.hd_dep_count,
      ib.ib_lower_bound,
      i.i_item_id,
      i.i_current_price,
      s.s_store_name,
      w.w_warehouse_name,
      d.d_year,
      t.t_shift,
      ss.ss_ticket_number         AS ticket_number,
      ss.ss_ext_sales_price       AS sales_price,
      ss.ss_net_paid              AS net_paid,
      ia.total_qty,
      ss_agg.store_net_paid,
      (
        SELECT MAX(r.r_reason_desc)
        FROM reason r
        WHERE r.r_reason_sk = sr.sr_reason_sk
      )                           AS max_reason_desc,
      CASE WHEN EXISTS (
        SELECT 1 FROM union_returns ur WHERE ur.cust_sk = c.c_customer_sk
      ) THEN 1 ELSE 0 END       AS has_return
    FROM store_sales ss
    JOIN date_dim d       ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN time_dim t       ON ss.ss_sold_time_sk = t.t_time_sk
    JOIN item i           ON ss.ss_item_sk = i.i_item_sk
    JOIN customer c       ON ss.ss_customer_sk = c.c_customer_sk
    JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib   ON hd.hd_income_band_sk = ib.ib_income_band_sk
    JOIN customer_address ca ON ss.ss_addr_sk = ca.ca_address_sk
    JOIN store s          ON ss.ss_store_sk = s.s_store_sk
    LEFT JOIN store_returns sr ON sr.sr_ticket_number = ss.ss_ticket_number
                               AND sr.sr_item_sk = ss.ss_item_sk
    LEFT JOIN inv_agg ia   ON ia.inv_item_sk = ss.ss_item_sk
    LEFT JOIN ss_agg       ON ss_agg.ss_item_sk = ss.ss_item_sk
                               AND ss_agg.ss_store_sk = ss.ss_store_sk
    LEFT JOIN warehouse w  ON ia.inv_warehouse_sk = w.w_warehouse_sk
    WHERE d.d_year = 2001
      AND t.t_shift = 'first'
      AND ca.ca_state = 'CA'
      AND i.i_brand = 'Brand#12'
      AND c.c_preferred_cust_flag = 'Y'
      AND s.s_market_id = 10
  ),
  web_branch AS (
    SELECT
      c.c_customer_sk,
      c.c_first_name,
      c.c_last_name,
      ca.ca_city,
      hd.hd_dep_count,
      ib.ib_lower_bound,
      i.i_item_id,
      i.i_current_price,
      CAST(NULL AS varchar)        AS s_store_name,
      w.w_warehouse_name,
      d.d_year,
      t.t_shift,
      ws.ws_order_number           AS ticket_number,
      ws.ws_ext_sales_price        AS sales_price,
      ws.ws_net_paid               AS net_paid,
      ia.total_qty,
      0                            AS store_net_paid,
      (
        SELECT MAX(r.r_reason_desc)
        FROM reason r
        WHERE r.r_reason_sk = wr.wr_reason_sk
      )                           AS max_reason_desc,
      CASE WHEN EXISTS (
        SELECT 1 FROM union_returns ur WHERE ur.cust_sk = c.c_customer_sk
      ) THEN 1 ELSE 0 END       AS has_return
    FROM web_sales ws
    JOIN date_dim d       ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN time_dim t       ON ws.ws_sold_time_sk = t.t_time_sk
    JOIN item i           ON ws.ws_item_sk = i.i_item_sk
    JOIN customer c       ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN household_demographics hd ON ws.ws_bill_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib   ON hd.hd_income_band_sk = ib.ib_income_band_sk
    JOIN customer_address ca ON ws.ws_bill_addr_sk = ca.ca_address_sk
    JOIN warehouse w      ON ws.ws_warehouse_sk = w.w_warehouse_sk
    LEFT JOIN web_returns wr ON wr.wr_order_number = ws.ws_order_number
                               AND wr.wr_item_sk = ws.ws_item_sk
    LEFT JOIN inv_agg ia   ON ia.inv_item_sk = ws.ws_item_sk
    WHERE d.d_year = 2001
      AND t.t_shift = 'second'
      AND ca.ca_state = 'TX'
      AND i.i_color = 'Red'
      AND c.c_preferred_cust_flag = 'N'
      AND w.w_state = 'WA'
  )
SELECT
  ub.c_customer_sk,
  ub.c_first_name,
  ub.c_last_name,
  ub.ca_city,
  ub.hd_dep_count,
  ub.ib_lower_bound,
  ub.i_item_id,
  ub.i_current_price,
  ub.s_store_name,
  ub.w_warehouse_name,
  ub.d_year,
  ub.t_shift,
  COUNT(DISTINCT ub.ticket_number)              AS distinct_tickets,
  SUM(DISTINCT ub.sales_price)                 AS sum_distinct_sales,
  SUM(ub.net_paid)                             AS total_net_paid,
  SUM(ub.total_qty)                            AS total_quantity,
  SUM(ub.store_net_paid)                       AS total_store_net_paid,
  MAX(ub.max_reason_desc)                      AS any_reason,
  BOOL_OR(ub.has_return = 1)                  AS any_return,
  lt.return_cnt                                AS customer_return_count
FROM (
  SELECT * FROM store_branch
  UNION
  SELECT * FROM web_branch
) ub
FULL OUTER JOIN store_returns sr_final
  ON sr_final.sr_customer_sk = ub.c_customer_sk
CROSS JOIN LATERAL (
  SELECT COUNT(*) AS return_cnt
  FROM store_returns sr2
  WHERE sr2.sr_customer_sk = ub.c_customer_sk
) lt
GROUP BY
  ub.c_customer_sk,
  ub.c_first_name,
  ub.c_last_name,
  ub.ca_city,
  ub.hd_dep_count,
  ub.ib_lower_bound,
  ub.i_item_id,
  ub.i_current_price,
  ub.s_store_name,
  ub.w_warehouse_name,
  ub.d_year,
  ub.t_shift,
  lt.return_cnt
HAVING SUM(ub.net_paid) > 1000
ORDER BY total_net_paid DESC
LIMIT 100

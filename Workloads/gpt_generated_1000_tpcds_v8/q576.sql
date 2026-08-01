WITH
  /* Aggregate sales and returns per year, month, category and ship mode */
  sales_agg AS (
    SELECT
      d.d_year,
      d.d_month_seq,
      i.i_category,
      sm.sm_type,
      w.w_state,
      SUM(ws.ws_ext_sales_price)                         AS total_sales,
      SUM(ws.ws_net_profit)                               AS total_profit,
      COUNT(DISTINCT ws.ws_order_number)                  AS orders_cnt,
      COALESCE(SUM(cr.cr_return_amount), 0)               AS total_return_amount,
      MIN(ws.ws_order_number)                             AS min_order_number,
      d.d_date_sk                                         AS sold_date_sk,
      i.i_item_sk                                         AS item_sk
    FROM web_sales ws
    JOIN date_dim d          ON ws.ws_sold_date_sk   = d.d_date_sk
    JOIN time_dim t          ON ws.ws_sold_time_sk   = t.t_time_sk
    JOIN item i              ON ws.ws_item_sk        = i.i_item_sk
    JOIN customer c          ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN ship_mode sm        ON ws.ws_ship_mode_sk   = sm.sm_ship_mode_sk
    JOIN warehouse w         ON ws.ws_warehouse_sk   = w.w_warehouse_sk
    LEFT JOIN catalog_returns cr
      ON cr.cr_item_sk                = i.i_item_sk
     AND cr.cr_returned_date_sk       = d.d_date_sk
     AND cr.cr_returned_time_sk       = t.t_time_sk
     AND cr.cr_ship_mode_sk           = sm.sm_ship_mode_sk
     AND cr.cr_warehouse_sk           = w.w_warehouse_sk
     AND cr.cr_refunded_customer_sk   = c.c_customer_sk
    WHERE d.d_year = 2001                                          -- predicate 1
      AND i.i_brand_id IN (1003001, 10005006)                      -- predicate 2
      AND sm.sm_type = 'AIR'                                      -- predicate 3
      AND w.w_state = 'CA'                                         -- predicate 4
      AND c.c_preferred_cust_flag = 'Y'                           -- predicate 5
      AND ws.ws_net_paid > 1000                                   -- predicate 6
      AND ws.ws_ext_discount_amt < 500
      AND i.i_category = 'Electronics'
      AND d.d_month_seq BETWEEN 1 AND 12
    GROUP BY
      d.d_year,
      d.d_month_seq,
      i.i_category,
      sm.sm_type,
      w.w_state,
      d.d_date_sk,
      i.i_item_sk
  ),

  /* Orders that appear both in sales and in returns for the same year */
  intersect_orders AS (
    SELECT ws.ws_order_number
    FROM web_sales ws
    JOIN date_dim d1 ON ws.ws_sold_date_sk = d1.d_date_sk
    WHERE d1.d_year = 2001
    INTERSECT
    SELECT cr.cr_order_number
    FROM catalog_returns cr
    JOIN date_dim d2 ON cr.cr_returned_date_sk = d2.d_date_sk
    WHERE d2.d_year = 2001
  ),

  /* Final result with further calculations, window functions and correlated sub‑queries */
  final_result AS (
    SELECT
      sa.d_year,
      sa.d_month_seq,
      sa.i_category,
      sa.sm_type,
      sa.w_state,
      sa.total_sales,
      sa.total_profit,
      sa.orders_cnt,
      sa.total_return_amount,
      /* Running total of sales per category ordered by month */
      SUM(sa.total_sales) OVER (PARTITION BY sa.i_category ORDER BY sa.d_month_seq
                                ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS running_sales_by_cat,
      /* Prior month profit for the same category */
      LAG(sa.total_profit) OVER (PARTITION BY sa.i_category ORDER BY sa.d_month_seq) AS prior_month_profit,
      /* Correlated scalar sub‑query: total sales of the same item on the same day */
      (
        SELECT SUM(ws3.ws_ext_sales_price)
        FROM web_sales ws3
        WHERE ws3.ws_item_sk = sa.item_sk
          AND ws3.ws_sold_date_sk = sa.sold_date_sk
      ) AS item_day_sales,
      /* Anti‑join condition: keep rows where no large return (> $500) exists for the representative order */
      CASE WHEN NOT EXISTS (
        SELECT 1
        FROM catalog_returns cr5
        WHERE cr5.cr_order_number = sa.min_order_number
          AND cr5.cr_return_amount > 500
      ) THEN 1 ELSE 0 END AS has_no_large_return
    FROM sales_agg sa
    WHERE sa.min_order_number IN (SELECT ws_order_number FROM intersect_orders)
  )
SELECT
  fr.d_year,
  fr.d_month_seq,
  fr.i_category,
  fr.sm_type,
  fr.w_state,
  fr.total_sales,
  fr.total_profit,
  fr.orders_cnt,
  fr.total_return_amount,
  fr.running_sales_by_cat,
  fr.prior_month_profit,
  fr.item_day_sales
FROM final_result fr
WHERE fr.has_no_large_return = 1
ORDER BY fr.d_year, fr.d_month_seq, fr.i_category
LIMIT 100

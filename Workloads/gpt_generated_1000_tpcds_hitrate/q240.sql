WITH inv_agg AS (
    SELECT
        inv_warehouse_sk,
        inv_date_sk,
        SUM(inv_quantity_on_hand) AS total_qty
    FROM inventory
    GROUP BY inv_warehouse_sk, inv_date_sk
)
SELECT
    cc.cc_state,
    w.w_state,
    c.c_birth_country,
    d_sold.d_year,
    d_sold.d_month_seq,
    SUM(cs.cs_net_paid) AS total_catalog_sales,
    SUM(ws.ws_net_paid_inc_tax) AS total_web_sales,
    AVG(ia.total_qty) AS avg_inventory_qty,
    COUNT(DISTINCT cs.cs_order_number) AS distinct_orders,
    MAX(sr.sr_store_credit) AS max_store_credit,
    MIN(sr.sr_refunded_cash) AS min_refunded_cash
FROM catalog_sales cs
JOIN date_dim d_sold
  ON cs.cs_sold_date_sk = d_sold.d_date_sk
JOIN time_dim t_sold
  ON cs.cs_sold_time_sk = t_sold.t_time_sk
JOIN catalog_page cp
  ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
JOIN call_center cc
  ON cs.cs_call_center_sk = cc.cc_call_center_sk
JOIN warehouse w
  ON cs.cs_warehouse_sk = w.w_warehouse_sk
JOIN customer c
  ON cs.cs_bill_customer_sk = c.c_customer_sk
JOIN date_dim d_ship
  ON cs.cs_ship_date_sk = d_ship.d_date_sk
JOIN web_sales ws
  ON ws.ws_sold_date_sk = d_sold.d_date_sk
JOIN date_dim d_ws_sold
  ON ws.ws_sold_date_sk = d_ws_sold.d_date_sk
JOIN time_dim t_ws_sold
  ON ws.ws_sold_time_sk = t_ws_sold.t_time_sk
JOIN date_dim d_ws_ship
  ON ws.ws_ship_date_sk = d_ws_ship.d_date_sk
JOIN warehouse w_ws
  ON ws.ws_warehouse_sk = w_ws.w_warehouse_sk
JOIN store_returns sr
  ON sr.sr_customer_sk = c.c_customer_sk
JOIN date_dim d_sr_ret
  ON sr.sr_returned_date_sk = d_sr_ret.d_date_sk
JOIN time_dim t_sr_ret
  ON sr.sr_return_time_sk = t_sr_ret.t_time_sk
JOIN reason r
  ON sr.sr_reason_sk = r.r_reason_sk
JOIN inv_agg ia
  ON ia.inv_warehouse_sk = w.w_warehouse_sk
  AND ia.inv_date_sk = d_sold.d_date_sk
WHERE
    cc.cc_state = 'CA'
    AND w.w_state = 'TX'
    AND c.c_birth_country = 'United States'
    AND d_sold.d_year = 2001
    AND d_sold.d_month_seq BETWEEN 1200 AND 1300
    AND r.r_reason_desc = 'Damaged'
    AND ia.total_qty > 500
    AND EXISTS (
        SELECT 1
        FROM store_returns sr2
        JOIN date_dim d2 ON sr2.sr_returned_date_sk = d2.d_date_sk
        WHERE sr2.sr_customer_sk = c.c_customer_sk
          AND d2.d_year = d_sold.d_year
    )
GROUP BY
    cc.cc_state,
    w.w_state,
    c.c_birth_country,
    d_sold.d_year,
    d_sold.d_month_seq
ORDER BY total_catalog_sales DESC
LIMIT 100

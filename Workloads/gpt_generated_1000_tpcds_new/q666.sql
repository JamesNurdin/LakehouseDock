WITH base AS (
  SELECT
    cp.cp_catalog_page_sk,
    cp.cp_department,
    w.w_warehouse_sk,
    w.w_county,
    ib.ib_income_band_sk,
    ib.ib_lower_bound,
    ib.ib_upper_bound,
    hd.hd_demo_sk,
    hd.hd_vehicle_count,
    cr.cr_returned_date_sk,
    cr.cr_return_amount,
    cr.cr_fee,
    cr.cr_return_quantity,
    inv.inv_quantity_on_hand,
    inv.inv_date_sk,
    td_cr.t_hour,
    CASE WHEN ib.ib_lower_bound >= 100000 THEN 'high' ELSE 'medium' END AS income_level
  FROM catalog_returns cr
  JOIN catalog_page cp
    ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
  JOIN warehouse w
    ON cr.cr_warehouse_sk = w.w_warehouse_sk
  JOIN household_demographics hd
    ON cr.cr_refunded_hdemo_sk = hd.hd_demo_sk
  JOIN income_band ib
    ON hd.hd_income_band_sk = ib.ib_income_band_sk
  JOIN inventory inv
    ON w.w_warehouse_sk = inv.inv_warehouse_sk
  JOIN time_dim td_cr
    ON cr.cr_returned_time_sk = td_cr.t_time_sk
  WHERE cp.cp_department IN ('Electronics', 'Books')
    AND w.w_county = 'Williamson County'
    AND ib.ib_lower_bound >= 70000
    AND inv.inv_quantity_on_hand > 0
    AND td_cr.t_hour BETWEEN 8 AND 20
    AND hd.hd_vehicle_count >= 1
    AND cr.cr_catalog_page_sk IN (
        SELECT cp2.cp_catalog_page_sk
        FROM catalog_page cp2
        WHERE cp2.cp_department = 'Books'
    )
),
returns_agg AS (
  SELECT
    b.w_warehouse_sk,
    b.w_county,
    b.cp_department,
    SUM(b.cr_return_amount) AS sum_catalog_ret_amt,
    SUM(sr.sr_return_amt) AS sum_store_ret_amt,
    SUM(wr.wr_return_amt) AS sum_web_ret_amt,
    COUNT(DISTINCT b.cr_returned_date_sk) AS cnt_catalog_days,
    COUNT(DISTINCT sr.sr_ticket_number) AS cnt_store_tickets,
    COUNT(DISTINCT wr.wr_order_number) AS cnt_web_orders
  FROM base b
  JOIN store_returns sr
    ON sr.sr_hdemo_sk = b.hd_demo_sk
  JOIN time_dim td_sr
    ON sr.sr_return_time_sk = td_sr.t_time_sk
  JOIN web_returns wr
    ON wr.wr_refunded_hdemo_sk = b.hd_demo_sk
  JOIN time_dim td_wr
    ON wr.wr_returned_time_sk = td_wr.t_time_sk
  WHERE td_sr.t_hour BETWEEN 9 AND 18
    AND td_wr.t_hour BETWEEN 9 AND 18
    AND wr.wr_fee > 0
    AND sr.sr_return_quantity > 0
  GROUP BY GROUPING SETS (
    (b.w_warehouse_sk, b.w_county, b.cp_department),
    (b.w_warehouse_sk, b.w_county),
    (b.cp_department)
  )
)
SELECT
  sub.w_warehouse_sk,
  sub.w_county,
  sub.cp_department,
  sub.sum_catalog_ret_amt,
  sub.sum_store_ret_amt,
  sub.sum_web_ret_amt,
  sub.cnt_catalog_days,
  sub.cnt_store_tickets,
  sub.cnt_web_orders,
  sub.rn
FROM (
  SELECT
    r.w_warehouse_sk,
    r.w_county,
    r.cp_department,
    r.sum_catalog_ret_amt,
    r.sum_store_ret_amt,
    r.sum_web_ret_amt,
    r.cnt_catalog_days,
    r.cnt_store_tickets,
    r.cnt_web_orders,
    ROW_NUMBER() OVER (PARTITION BY r.w_warehouse_sk ORDER BY r.sum_catalog_ret_amt DESC) AS rn
  FROM returns_agg r
) sub
WHERE sub.rn <= 3
ORDER BY sub.w_warehouse_sk, sub.rn

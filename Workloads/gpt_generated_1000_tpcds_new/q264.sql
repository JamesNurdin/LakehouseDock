WITH avg_return AS (
    SELECT avg(cr_return_amount) AS avg_ret_amount
    FROM catalog_returns
)
SELECT
    cp.cp_department,
    i.i_item_id,
    c_refunded.c_customer_id,
    hd_refunded.hd_buy_potential,
    ib.ib_lower_bound,
    r.r_reason_desc,
    sm.sm_type,
    w.w_warehouse_name,
    d_ret.d_date AS return_date,
    d_ret.d_year,
    cr.cr_return_amount,
    cr.cr_fee,
    cr.cr_return_ship_cost,
    cr.cr_refunded_cash,
    cr.cr_store_credit,
    cr.cr_net_loss,
    cr.cr_return_amount - (SELECT avg_ret_amount FROM avg_return) AS excess_return_amount,
    ROW_NUMBER() OVER (PARTITION BY cp.cp_department ORDER BY cr.cr_return_amount DESC) AS dept_return_rank,
    RANK() OVER (ORDER BY cr.cr_return_amount DESC) AS overall_return_rank
FROM catalog_returns cr
JOIN date_dim d_ret
  ON cr.cr_returned_date_sk = d_ret.d_date_sk
JOIN time_dim t_ret
  ON cr.cr_returned_time_sk = t_ret.t_time_sk
JOIN item i
  ON cr.cr_item_sk = i.i_item_sk
JOIN customer c_refunded
  ON cr.cr_refunded_customer_sk = c_refunded.c_customer_sk
JOIN customer_demographics cd_refunded
  ON cr.cr_refunded_cdemo_sk = cd_refunded.cd_demo_sk
JOIN household_demographics hd_refunded
  ON cr.cr_refunded_hdemo_sk = hd_refunded.hd_demo_sk
JOIN income_band ib
  ON hd_refunded.hd_income_band_sk = ib.ib_income_band_sk
JOIN catalog_page cp
  ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
JOIN ship_mode sm
  ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
JOIN warehouse w
  ON cr.cr_warehouse_sk = w.w_warehouse_sk
JOIN reason r
  ON cr.cr_reason_sk = r.r_reason_sk
-- store_sales and its related dimensions
JOIN store_sales ss
  ON ss.ss_item_sk = i.i_item_sk
JOIN date_dim d_sales
  ON ss.ss_sold_date_sk = d_sales.d_date_sk
JOIN customer c_sales
  ON ss.ss_customer_sk = c_sales.c_customer_sk
JOIN customer_demographics cd_sales
  ON ss.ss_cdemo_sk = cd_sales.cd_demo_sk
JOIN household_demographics hd_sales
  ON ss.ss_hdemo_sk = hd_sales.hd_demo_sk
-- store_returns linked to store_sales
JOIN store_returns sr
  ON sr.sr_ticket_number = ss.ss_ticket_number
 AND sr.sr_item_sk = ss.ss_item_sk
-- web_returns (independent join via item & date)
JOIN web_returns wr
  ON wr.wr_item_sk = i.i_item_sk
JOIN date_dim d_wr
  ON wr.wr_returned_date_sk = d_wr.d_date_sk
-- web_site linked via its open date
JOIN web_site wsit
  ON wsit.web_open_date_sk = d_ret.d_date_sk
WHERE d_ret.d_year = 2000
  AND i.i_current_price > 100
  AND hd_refunded.hd_buy_potential = 'High'
  AND ib.ib_upper_bound >= 80000
  AND r.r_reason_desc LIKE '%color%'
  AND w.w_warehouse_sq_ft > 150000
  AND wsit.web_country = 'United States'
ORDER BY cr.cr_return_amount DESC
LIMIT 100

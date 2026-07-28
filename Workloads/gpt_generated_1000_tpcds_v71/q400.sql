WITH cs AS (
    SELECT *
    FROM catalog_sales
)
SELECT
    i.i_category                         AS category,
    s.s_state                            AS state,
    d_sold.d_year                        AS year,
    COUNT(DISTINCT cs.cs_order_number)  AS orders,
    SUM(cs.cs_net_paid)                 AS total_sales,
    SUM(cr.cr_return_amount)            AS total_returns,
    SUM(ws.ws_net_paid)                 AS total_web_sales,
    AVG(i.i_current_price)              AS avg_price,
    MIN(cs.cs_sold_date_sk)             AS min_sold_date_sk,
    MAX(cs.cs_sold_date_sk)             AS max_sold_date_sk
FROM catalog_sales cs
JOIN catalog_page cp
  ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
JOIN customer c_bill
  ON cs.cs_bill_customer_sk = c_bill.c_customer_sk
JOIN customer c_ship
  ON cs.cs_ship_customer_sk = c_ship.c_customer_sk
JOIN customer_demographics cd_bill
  ON cs.cs_bill_cdemo_sk = cd_bill.cd_demo_sk
JOIN customer_demographics cd_ship
  ON cs.cs_ship_cdemo_sk = cd_ship.cd_demo_sk
JOIN household_demographics hd_bill
  ON cs.cs_bill_hdemo_sk = hd_bill.hd_demo_sk
JOIN household_demographics hd_ship
  ON cs.cs_ship_hdemo_sk = hd_ship.hd_demo_sk
JOIN date_dim d_sold
  ON cs.cs_sold_date_sk = d_sold.d_date_sk
JOIN date_dim d_ship
  ON cs.cs_ship_date_sk = d_ship.d_date_sk
JOIN time_dim t_sold
  ON cs.cs_sold_time_sk = t_sold.t_time_sk
JOIN item i
  ON cs.cs_item_sk = i.i_item_sk
JOIN promotion p
  ON cs.cs_promo_sk = p.p_promo_sk
JOIN ship_mode sm
  ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
JOIN catalog_returns cr
  ON cs.cs_order_number = cr.cr_order_number
JOIN reason r
  ON cr.cr_reason_sk = r.r_reason_sk
JOIN store s
  ON s.s_closed_date_sk = d_ship.d_date_sk
JOIN web_sales ws
  ON ws.ws_item_sk = i.i_item_sk
JOIN web_returns wr
  ON ws.ws_order_number = wr.wr_order_number
JOIN income_band ib
  ON hd_bill.hd_income_band_sk = ib.ib_income_band_sk
WHERE
    d_sold.d_year = 2001
    AND i.i_brand_id IN (8015002, 6016006)
    AND sm.sm_type = 'AIR'
    AND p.p_discount_active = 'Y'
    AND t_sold.t_hour BETWEEN 8 AND 12
GROUP BY
    i.i_category,
    s.s_state,
    d_sold.d_year
HAVING
    SUM(cs.cs_net_paid) > 1000000
ORDER BY
    total_sales DESC
LIMIT 100

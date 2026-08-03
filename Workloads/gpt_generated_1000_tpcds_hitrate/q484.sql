WITH sampled_ws AS (
    SELECT *
    FROM web_sales
    TABLESAMPLE BERNOULLI (10)
)
SELECT
    d_ws_sold.d_year,
    i.i_brand,
    ca_bill.ca_state,
    SUM(cr.cr_return_amount) AS sum_cr_return_amount,
    SUM(sr.sr_return_amt) AS sum_sr_return_amt,
    SUM(ws.ws_net_paid) AS sum_ws_net_paid,
    COUNT(DISTINCT ws.ws_order_number) AS distinct_orders
FROM sampled_ws ws
JOIN date_dim d_ws_sold
    ON ws.ws_sold_date_sk = d_ws_sold.d_date_sk
JOIN time_dim t_ws_sold
    ON ws.ws_sold_time_sk = t_ws_sold.t_time_sk
JOIN item i
    ON ws.ws_item_sk = i.i_item_sk
JOIN ship_mode sm_ws
    ON ws.ws_ship_mode_sk = sm_ws.sm_ship_mode_sk
JOIN promotion p
    ON ws.ws_promo_sk = p.p_promo_sk
JOIN customer_address ca_bill
    ON ws.ws_bill_addr_sk = ca_bill.ca_address_sk
JOIN customer_address ca_ship
    ON ws.ws_ship_addr_sk = ca_ship.ca_address_sk
-- catalog returns
JOIN catalog_returns cr
    ON cr.cr_item_sk = i.i_item_sk
JOIN date_dim d_cr_ret
    ON cr.cr_returned_date_sk = d_cr_ret.d_date_sk
JOIN time_dim t_cr_ret
    ON cr.cr_returned_time_sk = t_cr_ret.t_time_sk
JOIN ship_mode sm_cr
    ON cr.cr_ship_mode_sk = sm_cr.sm_ship_mode_sk
JOIN reason r_cr
    ON cr.cr_reason_sk = r_cr.r_reason_sk
JOIN customer_address ca_cr_refund
    ON cr.cr_refunded_addr_sk = ca_cr_refund.ca_address_sk
JOIN customer_address ca_cr_return
    ON cr.cr_returning_addr_sk = ca_cr_return.ca_address_sk
-- store returns
JOIN store_returns sr
    ON sr.sr_item_sk = i.i_item_sk
JOIN date_dim d_sr_ret
    ON sr.sr_returned_date_sk = d_sr_ret.d_date_sk
JOIN time_dim t_sr_ret
    ON sr.sr_return_time_sk = t_sr_ret.t_time_sk
JOIN store s
    ON sr.sr_store_sk = s.s_store_sk
JOIN reason r_sr
    ON sr.sr_reason_sk = r_sr.r_reason_sk
JOIN customer_address ca_sr_addr
    ON sr.sr_addr_sk = ca_sr_addr.ca_address_sk
-- web returns
JOIN web_returns wr
    ON wr.wr_order_number = ws.ws_order_number
   AND wr.wr_item_sk = ws.ws_item_sk
JOIN date_dim d_wr_ret
    ON wr.wr_returned_date_sk = d_wr_ret.d_date_sk
JOIN time_dim t_wr_ret
    ON wr.wr_returned_time_sk = t_wr_ret.t_time_sk
JOIN customer_address ca_wr_refund
    ON wr.wr_refunded_addr_sk = ca_wr_refund.ca_address_sk
JOIN customer_address ca_wr_return
    ON wr.wr_returning_addr_sk = ca_wr_return.ca_address_sk
JOIN reason r_wr
    ON wr.wr_reason_sk = r_wr.r_reason_sk
WHERE d_ws_sold.d_year = 2001
  AND i.i_brand = 'Brand#12'
  AND p.p_purpose = 'Promotion'
  AND ca_bill.ca_state = 'CA'
  AND ws.ws_quantity > 20
GROUP BY GROUPING SETS (
    (d_ws_sold.d_year, i.i_brand, ca_bill.ca_state),
    (d_ws_sold.d_year, i.i_brand),
    (ca_bill.ca_state),
    ()
)
UNION DISTINCT
SELECT
    d_ws_sold.d_year,
    i.i_brand,
    ca_bill.ca_state,
    SUM(cr.cr_return_amount) AS sum_cr_return_amount,
    SUM(sr.sr_return_amt) AS sum_sr_return_amt,
    SUM(ws.ws_net_paid) AS sum_ws_net_paid,
    COUNT(DISTINCT ws.ws_order_number) AS distinct_orders
FROM sampled_ws ws
JOIN date_dim d_ws_sold
    ON ws.ws_sold_date_sk = d_ws_sold.d_date_sk
JOIN time_dim t_ws_sold
    ON ws.ws_sold_time_sk = t_ws_sold.t_time_sk
JOIN item i
    ON ws.ws_item_sk = i.i_item_sk
JOIN ship_mode sm_ws
    ON ws.ws_ship_mode_sk = sm_ws.sm_ship_mode_sk
JOIN promotion p
    ON ws.ws_promo_sk = p.p_promo_sk
JOIN customer_address ca_bill
    ON ws.ws_bill_addr_sk = ca_bill.ca_address_sk
JOIN customer_address ca_ship
    ON ws.ws_ship_addr_sk = ca_ship.ca_address_sk
-- catalog returns
JOIN catalog_returns cr
    ON cr.cr_item_sk = i.i_item_sk
JOIN date_dim d_cr_ret
    ON cr.cr_returned_date_sk = d_cr_ret.d_date_sk
JOIN time_dim t_cr_ret
    ON cr.cr_returned_time_sk = t_cr_ret.t_time_sk
JOIN ship_mode sm_cr
    ON cr.cr_ship_mode_sk = sm_cr.sm_ship_mode_sk
JOIN reason r_cr
    ON cr.cr_reason_sk = r_cr.r_reason_sk
JOIN customer_address ca_cr_refund
    ON cr.cr_refunded_addr_sk = ca_cr_refund.ca_address_sk
JOIN customer_address ca_cr_return
    ON cr.cr_returning_addr_sk = ca_cr_return.ca_address_sk
-- store returns
JOIN store_returns sr
    ON sr.sr_item_sk = i.i_item_sk
JOIN date_dim d_sr_ret
    ON sr.sr_returned_date_sk = d_sr_ret.d_date_sk
JOIN time_dim t_sr_ret
    ON sr.sr_return_time_sk = t_sr_ret.t_time_sk
JOIN store s
    ON sr.sr_store_sk = s.s_store_sk
JOIN reason r_sr
    ON sr.sr_reason_sk = r_sr.r_reason_sk
JOIN customer_address ca_sr_addr
    ON sr.sr_addr_sk = ca_sr_addr.ca_address_sk
-- web returns
JOIN web_returns wr
    ON wr.wr_order_number = ws.ws_order_number
   AND wr.wr_item_sk = ws.ws_item_sk
JOIN date_dim d_wr_ret
    ON wr.wr_returned_date_sk = d_wr_ret.d_date_sk
JOIN time_dim t_wr_ret
    ON wr.wr_returned_time_sk = t_wr_ret.t_time_sk
JOIN customer_address ca_wr_refund
    ON wr.wr_refunded_addr_sk = ca_wr_refund.ca_address_sk
JOIN customer_address ca_wr_return
    ON wr.wr_returning_addr_sk = ca_wr_return.ca_address_sk
JOIN reason r_wr
    ON wr.wr_reason_sk = r_wr.r_reason_sk
WHERE d_ws_sold.d_year = 2002
  AND i.i_brand = 'Brand#23'
  AND p.p_purpose = 'Clearance'
  AND ca_bill.ca_state = 'NY'
  AND ws.ws_quantity > 30
GROUP BY GROUPING SETS (
    (d_ws_sold.d_year, i.i_brand, ca_bill.ca_state),
    (d_ws_sold.d_year, i.i_brand),
    (ca_bill.ca_state),
    ()
)
ORDER BY 1, 2, 3
LIMIT 100

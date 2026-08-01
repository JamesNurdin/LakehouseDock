WITH sr AS (
    SELECT
        sr_returned_date_sk,
        sr_return_time_sk,
        sr_customer_sk,
        sr_store_sk,
        sr_item_sk,
        sr_return_quantity,
        sr_return_amt,
        sr_return_tax,
        sr_return_amt_inc_tax,
        sr_fee,
        sr_return_ship_cost,
        sr_refunded_cash,
        sr_reversed_charge,
        sr_store_credit,
        sr_net_loss,
        sr_ticket_number
    FROM store_returns
)
SELECT
    cc.cc_market_manager,
    cc.cc_mkt_id,
    s.s_store_name,
    s.s_state,
    d_sr.d_year,
    d_sr.d_month_seq,
    t_sr.t_hour,
    COUNT(DISTINCT sr.sr_ticket_number)                         AS total_tickets,
    SUM(sr.sr_return_amt)                                        AS total_return_amt,
    SUM(sr.sr_net_loss)                                          AS total_net_loss,
    AVG(inv.inv_quantity_on_hand)                                AS avg_inventory_qty,
    SUM(wr.wr_return_amt)                                        AS total_web_return_amt,
    COUNT(wr.wr_return_quantity)                                 AS total_web_return_qty
FROM sr
JOIN date_dim d_sr
     ON sr.sr_returned_date_sk = d_sr.d_date_sk
JOIN time_dim t_sr
     ON sr.sr_return_time_sk = t_sr.t_time_sk
JOIN customer c
     ON sr.sr_customer_sk = c.c_customer_sk
JOIN store s
     ON sr.sr_store_sk = s.s_store_sk
JOIN date_dim d_store
     ON s.s_closed_date_sk = d_store.d_date_sk
JOIN call_center cc
     ON cc.cc_closed_date_sk = d_store.d_date_sk
JOIN inventory inv
     ON inv.inv_date_sk = d_store.d_date_sk
JOIN warehouse w
     ON inv.inv_warehouse_sk = w.w_warehouse_sk
LEFT JOIN web_returns wr
     ON wr.wr_returned_date_sk = d_store.d_date_sk
    AND wr.wr_returned_time_sk = t_sr.t_time_sk
    AND (wr.wr_refunded_customer_sk = c.c_customer_sk
         OR wr.wr_returning_customer_sk = c.c_customer_sk)
WHERE d_sr.d_date BETWEEN DATE '2001-01-01' AND DATE '2001-12-31'
  AND s.s_state = 'TX'
  AND c.c_preferred_cust_flag = 'Y'
  AND w.w_county = 'Richland County'
  AND inv.inv_quantity_on_hand > 100
  AND cc.cc_mkt_id IN (1, 2, 3)
  AND sr.sr_return_amt > (
        SELECT AVG(sr2.sr_return_amt)
        FROM store_returns sr2
        JOIN date_dim d2 ON sr2.sr_returned_date_sk = d2.d_date_sk
        WHERE d2.d_year = 2001
    )
GROUP BY
    cc.cc_market_manager,
    cc.cc_mkt_id,
    s.s_store_name,
    s.s_state,
    d_sr.d_year,
    d_sr.d_month_seq,
    t_sr.t_hour
HAVING SUM(sr.sr_return_amt) > 5000
ORDER BY total_return_amt DESC
LIMIT 100

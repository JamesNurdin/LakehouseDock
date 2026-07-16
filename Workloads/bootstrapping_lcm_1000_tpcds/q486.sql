SELECT
    s.s_store_id,
    s.s_store_name,
    s.s_city AS store_city,
    ca_ret.ca_city AS returning_city,
    ca_ret.ca_state AS returning_state,
    ca_ref.ca_city AS refunded_city,
    d_return.d_year,
    d_return.d_month_seq,
    p.p_promo_id,
    p.p_promo_name,
    d_pstart.d_date AS promo_start_date,
    d_pend.d_date AS promo_end_date,
    d_store.d_date AS store_closed_date,
    COUNT(*) AS num_returns,
    SUM(wr.wr_return_amt) AS total_return_amount,
    SUM(wr.wr_net_loss) AS total_net_loss,
    SUM(wr.wr_fee) AS total_fee,
    AVG(wr.wr_return_quantity) AS avg_return_quantity
FROM web_returns wr
JOIN date_dim d_return
    ON wr.wr_returned_date_sk = d_return.d_date_sk
JOIN customer_address ca_ret
    ON wr.wr_returning_addr_sk = ca_ret.ca_address_sk
JOIN customer_address ca_ref
    ON wr.wr_refunded_addr_sk = ca_ref.ca_address_sk
JOIN store s
    ON s.s_closed_date_sk = d_return.d_date_sk
JOIN date_dim d_store
    ON s.s_closed_date_sk = d_store.d_date_sk
JOIN promotion p
    ON p.p_start_date_sk = d_return.d_date_sk
JOIN date_dim d_pstart
    ON p.p_start_date_sk = d_pstart.d_date_sk
JOIN date_dim d_pend
    ON p.p_end_date_sk = d_pend.d_date_sk
WHERE d_pstart.d_date <= d_return.d_date
  AND d_pend.d_date >= d_return.d_date
GROUP BY
    s.s_store_id,
    s.s_store_name,
    s.s_city,
    ca_ret.ca_city,
    ca_ret.ca_state,
    ca_ref.ca_city,
    d_return.d_year,
    d_return.d_month_seq,
    p.p_promo_id,
    p.p_promo_name,
    d_pstart.d_date,
    d_pend.d_date,
    d_store.d_date
ORDER BY total_return_amount DESC
LIMIT 100

SELECT
    d.d_year,
    d.d_month_seq,
    cc.cc_division_name AS cc_division,
    s.s_division_name AS store_division,
    p.p_promo_name,
    CASE WHEN p.p_discount_active = 'Y' THEN 'Discounted' ELSE 'Regular' END AS promo_type,
    COUNT(DISTINCT wr.wr_order_number) AS order_cnt,
    SUM(wr.wr_return_amt) AS total_return_amt,
    SUM(wr.wr_net_loss) AS total_net_loss,
    SUM(wr.wr_fee) AS total_fee,
    AVG(p.p_cost) AS avg_promo_cost,
    SUM(wr.wr_return_quantity) AS total_return_qty,
    SUM(wr.wr_return_amt) * AVG(p.p_cost) AS return_amt_times_avg_promo_cost
FROM web_returns wr
JOIN date_dim d
    ON wr.wr_returned_date_sk = d.d_date_sk
JOIN store s
    ON s.s_closed_date_sk = d.d_date_sk
JOIN call_center cc
    ON (cc.cc_open_date_sk = d.d_date_sk OR cc.cc_closed_date_sk = d.d_date_sk)
JOIN promotion p
    ON d.d_date_sk >= p.p_start_date_sk
   AND d.d_date_sk <= p.p_end_date_sk
WHERE d.d_year BETWEEN 2000 AND 2005
  AND s.s_state = 'CA'
  AND cc.cc_country = 'United States'
GROUP BY
    d.d_year,
    d.d_month_seq,
    cc.cc_division_name,
    s.s_division_name,
    p.p_promo_name,
    CASE WHEN p.p_discount_active = 'Y' THEN 'Discounted' ELSE 'Regular' END
HAVING SUM(wr.wr_return_amt) > 5000
ORDER BY d.d_year, d.d_month_seq, total_return_amt DESC
LIMIT 100

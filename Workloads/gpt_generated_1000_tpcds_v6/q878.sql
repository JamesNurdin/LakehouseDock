SELECT
    s.s_state,
    cp.cp_type,
    p.p_promo_name,
    d_sold.d_year,
    d_sold.d_month_seq,
    COUNT(*) AS sales_cnt,
    SUM(cs.cs_net_paid) AS total_net_paid,
    AVG(cs.cs_ext_discount_amt) AS avg_discount_amt,
    MIN(cs.cs_net_paid) AS min_net_paid,
    MAX(cs.cs_net_paid) AS max_net_paid
FROM catalog_sales cs
JOIN catalog_page cp
    ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
JOIN date_dim d_sold
    ON cs.cs_sold_date_sk = d_sold.d_date_sk
JOIN time_dim td
    ON cs.cs_sold_time_sk = td.t_time_sk
JOIN date_dim d_ship
    ON cs.cs_ship_date_sk = d_ship.d_date_sk
JOIN promotion p
    ON cs.cs_promo_sk = p.p_promo_sk
JOIN date_dim d_promo_start
    ON p.p_start_date_sk = d_promo_start.d_date_sk
JOIN store s
    ON s.s_closed_date_sk = d_promo_start.d_date_sk
JOIN date_dim d_cp_start
    ON cp.cp_start_date_sk = d_cp_start.d_date_sk
JOIN date_dim d_cp_end
    ON cp.cp_end_date_sk = d_cp_end.d_date_sk
WHERE d_sold.d_year = 2022
  AND d_ship.d_year = 2022
  AND p.p_channel_dmail = 'Y'
  AND cp.cp_type = 'monthly'
  AND s.s_state = 'CA'
  AND td.t_hour BETWEEN 9 AND 17
GROUP BY
    s.s_state,
    cp.cp_type,
    p.p_promo_name,
    d_sold.d_year,
    d_sold.d_month_seq
ORDER BY total_net_paid DESC
LIMIT 100

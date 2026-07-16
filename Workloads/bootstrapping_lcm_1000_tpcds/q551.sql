SELECT
    s.s_store_id,
    s.s_store_name,
    s.s_city,
    s.s_state,
    d_sold.d_year,
    d_sold.d_month_seq,
    cp.cp_department,
    cp.cp_type,
    COUNT(DISTINCT ss.ss_ticket_number) AS tickets_sold,
    SUM(ss.ss_ext_sales_price) AS total_sales,
    SUM(ss.ss_net_profit) AS total_profit,
    SUM(ss.ss_ext_discount_amt) AS total_discount,
    COUNT(DISTINCT p.p_promo_id) AS promo_count,
    AVG(p.p_cost) AS avg_promo_cost,
    MIN(d_promo_start.d_date) AS earliest_promo_start,
    MAX(d_promo_end.d_date) AS latest_promo_end,
    MIN(d_sold.d_date) AS catalog_page_start_date,
    MAX(d_cp_end.d_date) AS catalog_page_end_date,
    MAX(d_store_closed.d_date) AS store_closed_date
FROM store_sales ss
JOIN store s
    ON ss.ss_store_sk = s.s_store_sk
JOIN date_dim d_sold
    ON ss.ss_sold_date_sk = d_sold.d_date_sk
JOIN promotion p
    ON ss.ss_promo_sk = p.p_promo_sk
JOIN date_dim d_promo_start
    ON p.p_start_date_sk = d_promo_start.d_date_sk
JOIN date_dim d_promo_end
    ON p.p_end_date_sk = d_promo_end.d_date_sk
JOIN catalog_page cp
    ON cp.cp_start_date_sk = d_sold.d_date_sk
JOIN date_dim d_cp_end
    ON cp.cp_end_date_sk = d_cp_end.d_date_sk
JOIN date_dim d_store_closed
    ON s.s_closed_date_sk = d_store_closed.d_date_sk
WHERE d_sold.d_date BETWEEN d_promo_start.d_date AND d_promo_end.d_date
  AND d_sold.d_date <= d_cp_end.d_date
GROUP BY
    s.s_store_id,
    s.s_store_name,
    s.s_city,
    s.s_state,
    d_sold.d_year,
    d_sold.d_month_seq,
    cp.cp_department,
    cp.cp_type

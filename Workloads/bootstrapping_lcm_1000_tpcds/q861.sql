SELECT
    cp.cp_department,
    cp.cp_type,
    cp.cp_catalog_page_number,
    p.p_promo_name,
    p.p_purpose,
    s.s_state,
    s.s_market_desc,
    d.d_year,
    d.d_month_seq,
    COUNT(DISTINCT wr.wr_order_number) AS num_returns,
    SUM(wr.wr_return_amt) AS total_return_amount,
    SUM(wr.wr_return_tax) AS total_return_tax,
    SUM(wr.wr_net_loss) AS total_net_loss,
    SUM(p.p_cost) AS total_promo_cost,
    AVG(p.p_cost) AS avg_promo_cost,
    COUNT(DISTINCT cp.cp_catalog_page_id) AS distinct_pages,
    COUNT(DISTINCT p.p_promo_id) AS distinct_promos,
    SUM(wr.wr_return_amt) - SUM(p.p_cost) AS net_gain,
    SUM(CASE WHEN wr.wr_return_quantity > 1 THEN wr.wr_return_amt ELSE 0 END) AS multi_item_return_amount
FROM date_dim d
JOIN web_returns wr
    ON wr.wr_returned_date_sk = d.d_date_sk
JOIN store s
    ON s.s_closed_date_sk = d.d_date_sk
JOIN catalog_page cp
    ON cp.cp_end_date_sk = d.d_date_sk
   AND cp.cp_start_date_sk = d.d_date_sk
JOIN promotion p
    ON p.p_start_date_sk = d.d_date_sk
   AND p.p_end_date_sk = d.d_date_sk
WHERE d.d_year BETWEEN 2015 AND 2020
  AND p.p_cost > 0
  AND s.s_state IS NOT NULL
GROUP BY
    cp.cp_department,
    cp.cp_type,
    cp.cp_catalog_page_number,
    p.p_promo_name,
    p.p_purpose,
    s.s_state,
    s.s_market_desc,
    d.d_year,
    d.d_month_seq
HAVING SUM(wr.wr_return_amt) > 1000
   AND SUM(p.p_cost) > 500
ORDER BY net_gain DESC
LIMIT 100

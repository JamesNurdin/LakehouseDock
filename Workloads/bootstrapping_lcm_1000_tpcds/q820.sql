SELECT
    d_return.d_year,
    d_return.d_month_seq,
    CASE
        WHEN d_return.d_month_seq IN (12,1,2) THEN 'Winter'
        WHEN d_return.d_month_seq IN (3,4,5) THEN 'Spring'
        WHEN d_return.d_month_seq IN (6,7,8) THEN 'Summer'
        WHEN d_return.d_month_seq IN (9,10,11) THEN 'Fall'
        ELSE 'Unknown'
    END AS season,
    i.i_category,
    p.p_promo_name,
    s.s_division_name,
    COUNT(*) AS total_returns,
    SUM(wr.wr_return_quantity) AS total_return_quantity,
    SUM(wr.wr_return_amt) AS total_return_amount,
    SUM(wr.wr_net_loss) AS total_net_loss,
    AVG(p.p_cost) AS avg_promo_cost,
    SUM(p.p_cost) AS total_promo_cost,
    CASE
        WHEN SUM(wr.wr_return_quantity) > 0 THEN SUM(wr.wr_net_loss) / SUM(wr.wr_return_quantity)
        ELSE NULL
    END AS net_loss_per_item
FROM web_returns wr
JOIN date_dim d_return ON wr.wr_returned_date_sk = d_return.d_date_sk
JOIN item i ON wr.wr_item_sk = i.i_item_sk
JOIN promotion p ON p.p_item_sk = i.i_item_sk
JOIN date_dim d_promo_start ON p.p_start_date_sk = d_promo_start.d_date_sk
JOIN date_dim d_promo_end ON p.p_end_date_sk = d_promo_end.d_date_sk
JOIN store s ON s.s_closed_date_sk = d_return.d_date_sk
WHERE p.p_discount_active = 'Y'
  AND d_promo_start.d_date <= d_return.d_date
  AND d_promo_end.d_date >= d_return.d_date
GROUP BY
    d_return.d_year,
    d_return.d_month_seq,
    i.i_category,
    p.p_promo_name,
    s.s_division_name
HAVING COUNT(*) > 5
ORDER BY total_net_loss DESC
LIMIT 100

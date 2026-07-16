SELECT
    d_ret.d_year AS return_year,
    d_ret.d_quarter_name AS return_quarter,
    s.s_division_name AS store_division,
    p.p_promo_name AS promotion_name,
    r.r_reason_desc AS return_reason,
    CASE
        WHEN s.s_tax_percentage > 5 THEN 'HighTax'
        ELSE 'LowTax'
    END AS tax_category,
    COUNT(DISTINCT wr.wr_order_number) AS distinct_orders,
    SUM(wr.wr_return_quantity) AS total_return_qty,
    SUM(wr.wr_return_amt) AS total_return_amt,
    SUM(wr.wr_return_tax) AS total_return_tax,
    SUM(wr.wr_net_loss) AS total_net_loss,
    AVG(p.p_cost) AS avg_promo_cost,
    MIN(d_ret.d_date) AS return_date,
    MAX(d_end.d_date) AS promotion_end_date,
    SUM(CASE
            WHEN wr.wr_returned_date_sk BETWEEN p.p_start_date_sk AND p.p_end_date_sk
            THEN wr.wr_return_amt
            ELSE 0
        END) AS return_amt_during_promo,
    CASE
        WHEN SUM(wr.wr_return_amt) > 0 THEN SUM(wr.wr_net_loss) / SUM(wr.wr_return_amt)
        ELSE NULL
    END AS net_loss_ratio
FROM web_returns wr
JOIN date_dim d_ret
    ON wr.wr_returned_date_sk = d_ret.d_date_sk
JOIN reason r
    ON wr.wr_reason_sk = r.r_reason_sk
JOIN store s
    ON s.s_closed_date_sk = d_ret.d_date_sk
JOIN promotion p
    ON p.p_start_date_sk = d_ret.d_date_sk
JOIN date_dim d_end
    ON p.p_end_date_sk = d_end.d_date_sk
WHERE wr.wr_return_amt > 0
GROUP BY
    d_ret.d_year,
    d_ret.d_quarter_name,
    s.s_division_name,
    p.p_promo_name,
    r.r_reason_desc,
    CASE
        WHEN s.s_tax_percentage > 5 THEN 'HighTax'
        ELSE 'LowTax'
    END
HAVING SUM(wr.wr_return_quantity) > 10
ORDER BY total_net_loss DESC
LIMIT 100

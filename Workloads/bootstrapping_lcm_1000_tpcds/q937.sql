WITH
    store_closure AS (
        SELECT d.d_date_sk,
               COUNT(*) AS closed_store_cnt
        FROM store s
        JOIN date_dim d ON s.s_closed_date_sk = d.d_date_sk
        GROUP BY d.d_date_sk
    ),
    promo_start AS (
        SELECT p.p_start_date_sk AS d_date_sk,
               SUM(p.p_cost) AS total_promo_start_cost
        FROM promotion p
        GROUP BY p.p_start_date_sk
    ),
    promo_end AS (
        SELECT p.p_end_date_sk AS d_date_sk,
               SUM(p.p_cost) AS total_promo_end_cost
        FROM promotion p
        GROUP BY p.p_end_date_sk
    ),
    promo_costs AS (
        SELECT COALESCE(s.d_date_sk, e.d_date_sk) AS d_date_sk,
               s.total_promo_start_cost,
               e.total_promo_end_cost
        FROM promo_start s
        FULL OUTER JOIN promo_end e ON s.d_date_sk = e.d_date_sk
    )
SELECT
    d.d_year,
    d.d_month_seq,
    r.r_reason_desc,
    COUNT(DISTINCT w.wr_order_number) AS distinct_orders,
    SUM(w.wr_return_quantity) AS total_return_qty,
    SUM(w.wr_return_amt) AS total_return_amt,
    SUM(w.wr_return_amt_inc_tax) AS total_return_amt_inc_tax,
    COALESCE(MAX(pc.total_promo_start_cost), 0) AS total_promo_start_cost,
    COALESCE(MAX(pc.total_promo_end_cost), 0) AS total_promo_end_cost,
    COALESCE(MAX(sc.closed_store_cnt), 0) AS closed_store_cnt,
    AVG(w.wr_net_loss) AS avg_net_loss,
    SUM(w.wr_return_tax) AS total_return_tax,
    SUM(w.wr_fee) AS total_fee,
    SUM(w.wr_return_ship_cost) AS total_ship_cost,
    (SUM(w.wr_return_amt) / NULLIF(SUM(w.wr_return_quantity), 0)) AS avg_return_amt_per_qty,
    (SUM(w.wr_net_loss) / NULLIF(SUM(w.wr_return_amt), 0)) AS net_loss_ratio,
    CASE WHEN SUM(w.wr_net_loss) > 1000 THEN 'HIGH' ELSE 'NORMAL' END AS loss_category
FROM web_returns w
JOIN date_dim d ON w.wr_returned_date_sk = d.d_date_sk
JOIN reason r ON w.wr_reason_sk = r.r_reason_sk
LEFT JOIN store_closure sc ON d.d_date_sk = sc.d_date_sk
LEFT JOIN promo_costs pc ON d.d_date_sk = pc.d_date_sk
WHERE d.d_year BETWEEN 2019 AND 2021
GROUP BY
    d.d_year,
    d.d_month_seq,
    r.r_reason_desc
HAVING SUM(w.wr_return_quantity) > 10
ORDER BY d.d_year, d.d_month_seq, total_return_amt DESC
LIMIT 100

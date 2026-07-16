SELECT
    d.d_date,
    d.d_year,
    d.d_month_seq,
    COALESCE(w.total_return_amt, 0) AS total_return_amount,
    COALESCE(w.return_count, 0) AS return_count,
    COALESCE(s.stores_closed, 0) AS stores_closed,
    COALESCE(s.avg_store_employees, 0) AS avg_store_employees,
    COALESCE(cc.callcenters_closed, 0) AS call_centers_closed,
    COALESCE(cc.total_cc_employees, 0) AS total_cc_employees,
    COALESCE(p_start.total_promo_start_cost, 0) AS promo_start_cost_total,
    COALESCE(p_end.total_promo_end_cost, 0) AS promo_end_cost_total
FROM date_dim d
LEFT JOIN (
    SELECT wr_returned_date_sk AS date_sk,
           SUM(wr_return_amt) AS total_return_amt,
           COUNT(*) AS return_count
    FROM web_returns
    GROUP BY wr_returned_date_sk
) w ON w.date_sk = d.d_date_sk
LEFT JOIN (
    SELECT s_closed_date_sk AS date_sk,
           COUNT(*) AS stores_closed,
           AVG(s_number_employees) AS avg_store_employees
    FROM store
    GROUP BY s_closed_date_sk
) s ON s.date_sk = d.d_date_sk
LEFT JOIN (
    SELECT cc_closed_date_sk AS date_sk,
           COUNT(*) AS callcenters_closed,
           SUM(cc_employees) AS total_cc_employees
    FROM call_center
    GROUP BY cc_closed_date_sk
) cc ON cc.date_sk = d.d_date_sk
LEFT JOIN (
    SELECT p_start_date_sk AS date_sk,
           SUM(p_cost) AS total_promo_start_cost
    FROM promotion
    GROUP BY p_start_date_sk
) p_start ON p_start.date_sk = d.d_date_sk
LEFT JOIN (
    SELECT p_end_date_sk AS date_sk,
           SUM(p_cost) AS total_promo_end_cost
    FROM promotion
    GROUP BY p_end_date_sk
) p_end ON p_end.date_sk = d.d_date_sk
WHERE d.d_date BETWEEN DATE '2022-01-01' AND DATE '2022-12-31'
ORDER BY d.d_date
LIMIT 100

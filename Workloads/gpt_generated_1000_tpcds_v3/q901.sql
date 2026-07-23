WITH filtered_sales AS (
    SELECT
        ss.ss_sold_date_sk,
        ss.ss_sold_time_sk,
        ss.ss_net_paid_inc_tax,
        ss.ss_ext_wholesale_cost,
        ss.ss_sales_price,
        ss.ss_ext_discount_amt
    FROM store_sales ss
    WHERE ss.ss_net_paid_inc_tax > 1000
)
SELECT
    d.d_year,
    d.d_quarter_name,
    t.t_shift,
    SUM(ss.ss_net_paid_inc_tax) AS total_net_paid_inc_tax,
    AVG(ss.ss_ext_wholesale_cost) AS avg_wholesale_cost,
    COUNT(*) AS sales_count,
    MIN(ss.ss_sales_price) AS min_sales_price,
    MAX(ss.ss_ext_discount_amt) AS max_discount_amt
FROM filtered_sales ss
JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
JOIN time_dim t ON ss.ss_sold_time_sk = t.t_time_sk
WHERE d.d_year = 1998
  AND d.d_qoy = 2
  AND d.d_dom BETWEEN 1 AND 15
  AND t.t_shift = 'second'
  AND t.t_time >= 8
  AND t.t_minute = 10
GROUP BY d.d_year, d.d_quarter_name, t.t_shift
ORDER BY total_net_paid_inc_tax DESC
LIMIT 100

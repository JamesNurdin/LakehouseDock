SELECT
    d.d_year,
    s.s_state,
    CASE WHEN s.s_tax_percentage > 0.07 THEN 'HighTax' ELSE 'LowTax' END AS tax_category,
    CONCAT(s.s_city, ', ', s.s_state) AS city_state,
    d.d_month_seq,
    COUNT(DISTINCT c.c_customer_sk) AS num_customers,
    SUM(p.p_cost) AS total_promo_cost,
    AVG(i.i_wholesale_cost) AS avg_wholesale_cost,
    SUM(p.p_cost * i.i_wholesale_cost) AS weighted_cost,
    COUNT(*) AS total_rows
FROM customer c
JOIN date_dim d
    ON c.c_first_shipto_date_sk = d.d_date_sk
JOIN promotion p
    ON p.p_start_date_sk = d.d_date_sk
JOIN item i
    ON p.p_item_sk = i.i_item_sk
JOIN store s
    ON s.s_closed_date_sk = d.d_date_sk
WHERE d.d_year BETWEEN 2015 AND 2020
  AND p.p_discount_active = 'Y'
GROUP BY
    d.d_year,
    s.s_state,
    CASE WHEN s.s_tax_percentage > 0.07 THEN 'HighTax' ELSE 'LowTax' END,
    CONCAT(s.s_city, ', ', s.s_state),
    d.d_month_seq
HAVING COUNT(*) > 10
ORDER BY total_promo_cost DESC
LIMIT 100

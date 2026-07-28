/*
Goal: Analyze yearly sales by catalog department, categorizing customers by income band (high vs low), and compare total sales revenue with total returned amount. The query joins all nine TPC‑DS tables using the permitted surrogate‑key relationships, re‑uses the date_dim table under multiple aliases for different date roles, and includes a LEFT OUTER join to promotion to illustrate optional promotional data.
*/
SELECT
    d_sold.d_year,
    cp.cp_department,
    CASE
        WHEN ib.ib_upper_bound > 150000 THEN 'High'
        ELSE 'Low'
    END AS income_category,
    SUM(cs.cs_net_paid) AS total_sales,
    SUM(sr.sr_return_amt) AS total_returns,
    COUNT(DISTINCT cs.cs_order_number) AS distinct_orders
FROM catalog_sales cs
JOIN date_dim d_sold
    ON cs.cs_sold_date_sk = d_sold.d_date_sk
JOIN time_dim t_sold
    ON cs.cs_sold_time_sk = t_sold.t_time_sk
JOIN catalog_page cp
    ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
LEFT JOIN promotion p
    ON cs.cs_promo_sk = p.p_promo_sk
JOIN household_demographics hd
    ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
JOIN income_band ib
    ON hd.hd_income_band_sk = ib.ib_income_band_sk
JOIN store_returns sr
    ON sr.sr_hdemo_sk = hd.hd_demo_sk
JOIN store s
    ON sr.sr_store_sk = s.s_store_sk
JOIN date_dim d_closed
    ON s.s_closed_date_sk = d_closed.d_date_sk
JOIN time_dim t_return
    ON sr.sr_return_time_sk = t_return.t_time_sk
JOIN date_dim d_return
    ON sr.sr_returned_date_sk = d_return.d_date_sk
JOIN date_dim d_promo_start
    ON p.p_start_date_sk = d_promo_start.d_date_sk
JOIN date_dim d_promo_end
    ON p.p_end_date_sk = d_promo_end.d_date_sk
GROUP BY
    d_sold.d_year,
    cp.cp_department,
    CASE
        WHEN ib.ib_upper_bound > 150000 THEN 'High'
        ELSE 'Low'
    END
ORDER BY total_sales DESC
LIMIT 100

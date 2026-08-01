WITH sales AS (
    SELECT
        ss.ss_sold_date_sk,
        ss.ss_sold_time_sk,
        ss.ss_item_sk,
        ss.ss_customer_sk,
        ss.ss_cdemo_sk,
        ss.ss_hdemo_sk,
        ss.ss_store_sk,
        ss.ss_promo_sk,
        ss.ss_quantity,
        ss.ss_ext_discount_amt,
        ss.ss_net_paid,
        ss.ss_ext_sales_price
    FROM store_sales ss
)
SELECT
    s.s_store_name,
    i.i_category,
    d_sale.d_year,
    SUM(ss.ss_net_paid) AS total_net_paid,
    SUM(ss.ss_ext_discount_amt) AS total_discount,
    COUNT(DISTINCT c.c_customer_sk) AS distinct_customers,
    AVG(CASE WHEN ss.ss_ext_discount_amt > 100 THEN 1 ELSE 0 END) AS pct_high_discount,
    CASE
        WHEN SUM(ss.ss_net_paid) > 100000 THEN 'High Sales'
        WHEN SUM(ss.ss_net_paid) > 50000 THEN 'Medium Sales'
        ELSE 'Low Sales'
    END AS sales_tier
FROM sales ss
JOIN date_dim d_sale
    ON ss.ss_sold_date_sk = d_sale.d_date_sk
JOIN time_dim t
    ON ss.ss_sold_time_sk = t.t_time_sk
JOIN item i
    ON ss.ss_item_sk = i.i_item_sk
JOIN customer c
    ON ss.ss_customer_sk = c.c_customer_sk
JOIN customer_demographics cd
    ON ss.ss_cdemo_sk = cd.cd_demo_sk
JOIN household_demographics hd
    ON ss.ss_hdemo_sk = hd.hd_demo_sk
JOIN income_band ib
    ON hd.hd_income_band_sk = ib.ib_income_band_sk
JOIN store s
    ON ss.ss_store_sk = s.s_store_sk
JOIN promotion p
    ON ss.ss_promo_sk = p.p_promo_sk
JOIN date_dim d_store_closed
    ON s.s_closed_date_sk = d_store_closed.d_date_sk
JOIN date_dim d_promo_start
    ON p.p_start_date_sk = d_promo_start.d_date_sk
JOIN date_dim d_promo_end
    ON p.p_end_date_sk = d_promo_end.d_date_sk
WHERE d_sale.d_date BETWEEN DATE '2022-01-01' AND DATE '2022-12-31'
  AND NOT EXISTS (
        SELECT 1
        FROM promotion p2
        JOIN date_dim d2 ON p2.p_start_date_sk = d2.d_date_sk
        WHERE p2.p_promo_sk = ss.ss_promo_sk
          AND d2.d_date > d_sale.d_date
    )
GROUP BY
    s.s_store_name,
    i.i_category,
    d_sale.d_year
ORDER BY total_net_paid DESC
LIMIT 100

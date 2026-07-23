WITH agg_store_sales AS (
    SELECT
        ss_customer_sk,
        ss_sold_date_sk,
        ss_sold_time_sk,
        SUM(ss_ext_sales_price) AS total_sales,
        SUM(ss_quantity) AS total_quantity,
        AVG(ss_coupon_amt) AS avg_coupon_amt,
        COUNT(*) AS sales_count
    FROM store_sales
    WHERE ss_ext_sales_price > 1000
    GROUP BY ss_customer_sk, ss_sold_date_sk, ss_sold_time_sk
)
SELECT
    c.c_customer_id,
    ca.ca_city,
    ca.ca_state,
    d.d_date,
    t.t_hour,
    hd.hd_buy_potential,
    ib.ib_lower_bound,
    wp.wp_url,
    SUM(ws.total_sales) AS sum_total_sales,
    MIN(ws.total_sales) AS min_total_sales,
    MAX(ws.total_sales) AS max_total_sales,
    SUM(ws.total_quantity) AS sum_total_quantity,
    AVG(ws.avg_coupon_amt) AS avg_coupon_amt_overall,
    COUNT(DISTINCT ws.ss_customer_sk) AS distinct_customers,
    CASE WHEN ib.ib_lower_bound >= 100000 THEN 'High Income' ELSE 'Mid/Low Income' END AS income_category,
    SUM(wr.wr_return_amt) AS total_return_amount,
    COUNT(wr.wr_return_quantity) AS return_transactions
FROM agg_store_sales ws
JOIN customer c
    ON ws.ss_customer_sk = c.c_customer_sk
JOIN customer_address ca
    ON c.c_current_addr_sk = ca.ca_address_sk
JOIN date_dim d
    ON ws.ss_sold_date_sk = d.d_date_sk
JOIN time_dim t
    ON ws.ss_sold_time_sk = t.t_time_sk
JOIN household_demographics hd
    ON c.c_current_hdemo_sk = hd.hd_demo_sk
JOIN income_band ib
    ON hd.hd_income_band_sk = ib.ib_income_band_sk
JOIN web_returns wr
    ON wr.wr_returned_date_sk = d.d_date_sk
    AND wr.wr_returned_time_sk = t.t_time_sk
    AND wr.wr_refunded_customer_sk = c.c_customer_sk
JOIN web_page wp
    ON wr.wr_web_page_sk = wp.wp_web_page_sk
WHERE
    d.d_year = 2000
    AND d.d_month_seq BETWEEN 1200 AND 1210
    AND c.c_birth_year = 1970
    AND c.c_preferred_cust_flag = 'Y'
    AND ca.ca_state = 'CA'
    AND ib.ib_lower_bound >= 50000
    AND wp.wp_autogen_flag = 'N'
    AND wp.wp_type = 'article'
    AND wr.wr_return_amt > 200
GROUP BY
    c.c_customer_id,
    ca.ca_city,
    ca.ca_state,
    d.d_date,
    t.t_hour,
    hd.hd_buy_potential,
    ib.ib_lower_bound,
    wp.wp_url,
    CASE WHEN ib.ib_lower_bound >= 100000 THEN 'High Income' ELSE 'Mid/Low Income' END
ORDER BY sum_total_sales DESC
LIMIT 100

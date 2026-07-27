WITH ss_agg AS (
    SELECT
        ss_store_sk,
        ss_sold_date_sk,
        ss_customer_sk,
        ss_hdemo_sk,
        SUM(ss_ext_sales_price) AS total_sales,
        SUM(ss_net_profit) AS total_profit
    FROM store_sales
    WHERE ss_sold_date_sk BETWEEN 2450000 AND 2450200
    GROUP BY ss_store_sk, ss_sold_date_sk, ss_customer_sk, ss_hdemo_sk
),
sr_agg AS (
    SELECT
        sr_store_sk,
        sr_reason_sk,
        SUM(sr_return_amt) AS total_return_amt,
        COUNT(*) AS return_cnt
    FROM store_returns
    WHERE sr_returned_date_sk BETWEEN 2450000 AND 2450200
    GROUP BY sr_store_sk, sr_reason_sk
),
wp_distinct AS (
    SELECT DISTINCT
        wp_web_page_sk,
        wp_url,
        wp_type
    FROM web_page
    WHERE wp_type = 'article'
)
SELECT
    c.c_customer_id,
    s.s_store_name,
    ib.ib_lower_bound,
    sm.sm_type,
    r.r_reason_desc,
    wpd.wp_url,
    ss_agg.total_sales,
    ss_agg.total_profit,
    sr_agg.total_return_amt,
    DENSE_RANK() OVER (PARTITION BY s.s_store_name ORDER BY ss_agg.total_sales DESC) AS sales_rank,
    ROW_NUMBER() OVER (ORDER BY ss_agg.total_profit DESC) AS profit_row_num
FROM ss_agg
JOIN store s
    ON s.s_store_sk = ss_agg.ss_store_sk
JOIN customer c
    ON c.c_customer_sk = ss_agg.ss_customer_sk
JOIN household_demographics hd
    ON hd.hd_demo_sk = ss_agg.ss_hdemo_sk
JOIN income_band ib
    ON ib.ib_income_band_sk = hd.hd_income_band_sk
LEFT JOIN sr_agg
    ON sr_agg.sr_store_sk = s.s_store_sk
LEFT JOIN reason r
    ON r.r_reason_sk = sr_agg.sr_reason_sk
JOIN catalog_sales cs
    ON cs.cs_bill_customer_sk = c.c_customer_sk
JOIN ship_mode sm
    ON sm.sm_ship_mode_sk = cs.cs_ship_mode_sk
LEFT JOIN web_returns wr
    ON wr.wr_refunded_customer_sk = c.c_customer_sk
LEFT JOIN wp_distinct wpd
    ON wpd.wp_web_page_sk = wr.wr_web_page_sk
WHERE
    ib.ib_upper_bound <= 150000
    AND sm.sm_type = 'AIR'
    AND c.c_preferred_cust_flag = 'Y'
    AND cs.cs_sales_price > 50
GROUP BY
    c.c_customer_id,
    s.s_store_name,
    ib.ib_lower_bound,
    sm.sm_type,
    r.r_reason_desc,
    wpd.wp_url,
    ss_agg.total_sales,
    ss_agg.total_profit,
    sr_agg.total_return_amt
HAVING COUNT(DISTINCT r.r_reason_desc) > 0
ORDER BY ss_agg.total_sales DESC
LIMIT 100

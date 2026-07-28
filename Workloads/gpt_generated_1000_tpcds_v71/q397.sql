WITH base AS (
    SELECT
        r.r_reason_desc,
        t.t_hour,
        ss.ss_ticket_number,
        ss.ss_ext_sales_price,
        ss.ss_sales_price,
        ss.ss_quantity,
        wr.wr_return_amt,
        wr.wr_return_quantity,
        ca_ss.ca_state,
        ca_ss.ca_zip,
        wp.wp_type,
        hd_ss.hd_income_band_sk
    FROM store_sales ss
    JOIN time_dim t
        ON ss.ss_sold_time_sk = t.t_time_sk
    JOIN household_demographics hd_ss
        ON ss.ss_hdemo_sk = hd_ss.hd_demo_sk
    JOIN customer_address ca_ss
        ON ss.ss_addr_sk = ca_ss.ca_address_sk
    JOIN web_returns wr
        ON wr.wr_returned_time_sk = t.t_time_sk
    JOIN reason r
        ON wr.wr_reason_sk = r.r_reason_sk
    JOIN web_page wp
        ON wr.wr_web_page_sk = wp.wp_web_page_sk
    JOIN household_demographics hd_wr
        ON wr.wr_refunded_hdemo_sk = hd_wr.hd_demo_sk
    JOIN customer_address ca_wr
        ON wr.wr_refunded_addr_sk = ca_wr.ca_address_sk
    WHERE ca_ss.ca_state = 'TX'
      AND ca_ss.ca_zip = '98579'
      AND r.r_reason_desc LIKE 'Did not like the color%'
      AND t.t_hour BETWEEN 9 AND 17
      AND ss.ss_sales_price > 100
)
SELECT
    r_reason_desc,
    t_hour,
    COUNT(DISTINCT ss_ticket_number) AS num_sales,
    SUM(ss_ext_sales_price) AS total_sales,
    SUM(wr_return_amt) AS total_returns,
    AVG(ss_sales_price) AS avg_sale_price,
    ROW_NUMBER() OVER (PARTITION BY r_reason_desc ORDER BY SUM(ss_ext_sales_price) DESC) AS sales_rank
FROM base
GROUP BY r_reason_desc, t_hour
HAVING COUNT(DISTINCT ss_ticket_number) >= 5
ORDER BY total_sales DESC
LIMIT 100

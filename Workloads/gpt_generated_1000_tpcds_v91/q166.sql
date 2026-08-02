WITH store_ret AS (
    SELECT
        c.c_customer_id AS customer_id,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS customer_name,
        'store' AS source_type,
        r.r_reason_desc AS reason_desc,
        s.s_store_name AS location,
        SUM(sr.sr_return_amt) AS total_return_amt,
        COUNT(*) AS return_count,
        CASE WHEN SUM(sr.sr_return_amt) > 1000 THEN 'High' ELSE 'Low' END AS return_level,
        (
            SELECT COALESCE(SUM(ws.ws_ext_sales_price), 0)
            FROM web_sales ws
            WHERE ws.ws_bill_customer_sk = c.c_customer_sk
        ) AS total_sales_amount
    FROM store_returns sr
    JOIN customer c ON sr.sr_customer_sk = c.c_customer_sk
    JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
    JOIN store s ON sr.sr_store_sk = s.s_store_sk
    WHERE s.s_city = 'Springfield'
    GROUP BY
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        r.r_reason_desc,
        s.s_store_name,
        c.c_customer_sk
),
web_ret AS (
    SELECT
        c.c_customer_id AS customer_id,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS customer_name,
        'web' AS source_type,
        r.r_reason_desc AS reason_desc,
        wp.wp_url AS location,
        SUM(wr.wr_return_amt) AS total_return_amt,
        COUNT(*) AS return_count,
        CASE WHEN SUM(wr.wr_return_amt) > 1000 THEN 'High' ELSE 'Low' END AS return_level,
        (
            SELECT COALESCE(SUM(ws.ws_ext_sales_price), 0)
            FROM web_sales ws
            WHERE ws.ws_bill_customer_sk = c.c_customer_sk
        ) AS total_sales_amount
    FROM web_returns wr
    JOIN customer c ON wr.wr_refunded_customer_sk = c.c_customer_sk
    JOIN reason r ON wr.wr_reason_sk = r.r_reason_sk
    JOIN web_page wp ON wr.wr_web_page_sk = wp.wp_web_page_sk
    WHERE wp.wp_max_ad_count > 1
    GROUP BY
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        r.r_reason_desc,
        wp.wp_url,
        c.c_customer_sk
)
SELECT
    customer_id,
    customer_name,
    source_type,
    reason_desc,
    location,
    total_return_amt,
    return_count,
    return_level,
    total_sales_amount,
    RANK() OVER (ORDER BY total_return_amt DESC) AS return_rank
FROM (
    SELECT customer_id, customer_name, source_type, reason_desc, location, total_return_amt, return_count, return_level, total_sales_amount FROM store_ret
    UNION ALL
    SELECT customer_id, customer_name, source_type, reason_desc, location, total_return_amt, return_count, return_level, total_sales_amount FROM web_ret
) combined
ORDER BY total_return_amt DESC
LIMIT 100

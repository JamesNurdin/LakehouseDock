WITH filtered_returns AS (
    SELECT
        wr.wr_returned_date_sk,
        wr.wr_returned_time_sk,
        wr.wr_refunded_customer_sk,
        wr.wr_refunded_cdemo_sk,
        wr.wr_refunded_addr_sk,
        wr.wr_web_page_sk,
        wr.wr_reason_sk,
        wr.wr_return_amt,
        wr.wr_return_quantity
    FROM
        web_returns wr
    WHERE
        wr.wr_return_amt > (
            SELECT AVG(wr2.wr_return_amt)
            FROM web_returns wr2
            WHERE wr2.wr_returned_date_sk = wr.wr_returned_date_sk
        )
)
SELECT
    ws.web_name,
    r.r_reason_desc,
    d.d_year,
    SUM(fr.wr_return_amt) AS total_return_amount,
    COUNT(*) AS returns_cnt,
    AVG(fr.wr_return_quantity) AS avg_return_qty,
    MIN(fr.wr_return_amt) AS min_return_amt,
    MAX(fr.wr_return_amt) AS max_return_amt
FROM
    filtered_returns fr
JOIN date_dim d
    ON fr.wr_returned_date_sk = d.d_date_sk
JOIN time_dim t
    ON fr.wr_returned_time_sk = t.t_time_sk
JOIN customer cust
    ON fr.wr_refunded_customer_sk = cust.c_customer_sk
JOIN customer_demographics cd
    ON fr.wr_refunded_cdemo_sk = cd.cd_demo_sk
JOIN customer_address ca
    ON fr.wr_refunded_addr_sk = ca.ca_address_sk
JOIN web_page wp
    ON fr.wr_web_page_sk = wp.wp_web_page_sk
JOIN reason r
    ON fr.wr_reason_sk = r.r_reason_sk
JOIN web_site ws
    ON ws.web_open_date_sk = d.d_date_sk
JOIN promotion p
    ON p.p_start_date_sk = d.d_date_sk
WHERE
    d.d_year = 2001
    AND t.t_hour BETWEEN 9 AND 17
    AND cust.c_preferred_cust_flag = 'Y'
    AND ca.ca_state = 'CA'
    AND r.r_reason_desc LIKE '%warranty%'
    AND p.p_channel_event = 'N'
GROUP BY
    ws.web_name,
    r.r_reason_desc,
    d.d_year
HAVING
    SUM(fr.wr_return_amt) > 1000
ORDER BY
    total_return_amount DESC
LIMIT 100

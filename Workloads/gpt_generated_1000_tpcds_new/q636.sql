WITH customer_sales AS (
    SELECT
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        SUM(ws.ws_net_paid_inc_tax) AS total_paid
    FROM
        customer c
        JOIN web_sales ws ON ws.ws_bill_customer_sk = c.c_customer_sk
    GROUP BY
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name
)
SELECT
    result.c_customer_sk,
    result.c_first_name,
    result.c_last_name,
    result.amount,
    result.tier,
    result.web_name,
    result.order_cnt
FROM (
    SELECT DISTINCT
        cs.c_customer_sk,
        cs.c_first_name,
        cs.c_last_name,
        cs.total_paid AS amount,
        CASE WHEN cs.total_paid > 1000 THEN 'High' ELSE 'Low' END AS tier,
        ws_site.web_name,
        oc.order_cnt
    FROM
        customer_sales cs
        JOIN web_sales ws ON ws.ws_bill_customer_sk = cs.c_customer_sk
        JOIN web_site ws_site ON ws.ws_web_site_sk = ws_site.web_site_sk
        CROSS JOIN LATERAL (
            SELECT COUNT(*) AS order_cnt
            FROM web_sales ws2
            WHERE ws2.ws_bill_customer_sk = cs.c_customer_sk
        ) AS oc
    WHERE
        ws.ws_ship_cdemo_sk = 1249940
        AND ws_site.web_state = 'CA'

    UNION

    SELECT
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        SUM(wr.wr_return_amt) AS amount,
        CASE WHEN SUM(wr.wr_return_amt) > 200 THEN 'High Return' ELSE 'Low Return' END AS tier,
        ws_site.web_name,
        rc.return_cnt
    FROM
        customer c
        JOIN web_returns wr ON wr.wr_refunded_customer_sk = c.c_customer_sk
        JOIN web_sales ws ON ws.ws_order_number = wr.wr_order_number
        JOIN web_site ws_site ON ws.ws_web_site_sk = ws_site.web_site_sk
        CROSS JOIN LATERAL (
            SELECT COUNT(*) AS return_cnt
            FROM web_returns wr2
            WHERE wr2.wr_refunded_customer_sk = c.c_customer_sk
        ) AS rc
    WHERE
        ws_site.web_state = 'TX'
    GROUP BY
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        ws_site.web_name,
        rc.return_cnt
    HAVING
        SUM(wr.wr_return_amt) > 0
) AS result
ORDER BY
    result.amount DESC
LIMIT 100

WITH sampled_web_returns AS (
    SELECT *
    FROM web_returns TABLESAMPLE BERNOULLI (10)
),
union_data AS (
    /* First branch */
    SELECT
        cs.cs_order_number AS order_number,
        c_bill.c_customer_id AS bill_cust_id,
        c_ship.c_customer_id AS ship_cust_id,
        r_store.r_reason_desc AS store_ret_reason,
        r_web.r_reason_desc AS web_ret_reason,
        SUM(cs.cs_ext_sales_price) AS total_sales,
        COUNT(DISTINCT sr.sr_ticket_number) AS store_ret_cnt,
        COUNT(DISTINCT wr.wr_order_number) AS web_ret_cnt,
        CAST(
            (SELECT COALESCE(SUM(sr2.sr_return_amt), 0)
             FROM store_returns sr2
             WHERE sr2.sr_customer_sk = c_bill.c_customer_sk)
            AS double
        ) AS extra_metric
    FROM
        catalog_sales cs
        JOIN customer c_bill ON cs.cs_bill_customer_sk = c_bill.c_customer_sk
        JOIN customer c_ship ON cs.cs_ship_customer_sk = c_ship.c_customer_sk
        LEFT JOIN store_returns sr ON sr.sr_customer_sk = c_bill.c_customer_sk
        LEFT JOIN reason r_store ON sr.sr_reason_sk = r_store.r_reason_sk
        LEFT JOIN sampled_web_returns wr ON wr.wr_refunded_customer_sk = c_bill.c_customer_sk
        LEFT JOIN reason r_web ON wr.wr_reason_sk = r_web.r_reason_sk
        LEFT JOIN web_page wp ON wr.wr_web_page_sk = wp.wp_web_page_sk
    WHERE
        NOT EXISTS (
            SELECT 1
            FROM store_returns sr_chk
            WHERE sr_chk.sr_ticket_number = sr.sr_ticket_number
              AND sr_chk.sr_return_amt > 5000
        )
    GROUP BY
        cs.cs_order_number,
        c_bill.c_customer_id,
        c_ship.c_customer_id,
        r_store.r_reason_desc,
        r_web.r_reason_desc,
        c_bill.c_customer_sk

    UNION DISTINCT

    /* Second branch */
    SELECT
        cs2.cs_order_number AS order_number,
        c2.c_customer_id AS bill_cust_id,
        CAST(NULL AS varchar) AS ship_cust_id,
        r2_store.r_reason_desc AS store_ret_reason,
        r2_web.r_reason_desc AS web_ret_reason,
        SUM(cs2.cs_ext_sales_price) AS total_sales,
        0 AS store_ret_cnt,
        0 AS web_ret_cnt,
        CAST(
            (SELECT COUNT(*)
             FROM web_page wp2
             WHERE wp2.wp_customer_sk = c2.c_customer_sk)
            AS double
        ) AS extra_metric
    FROM
        catalog_sales cs2
        JOIN customer c2 ON cs2.cs_bill_customer_sk = c2.c_customer_sk
        FULL OUTER JOIN store_returns sr2 ON sr2.sr_customer_sk = c2.c_customer_sk
        FULL OUTER JOIN sampled_web_returns wr2 ON wr2.wr_refunded_customer_sk = c2.c_customer_sk
        LEFT JOIN reason r2_store ON sr2.sr_reason_sk = r2_store.r_reason_sk
        LEFT JOIN reason r2_web ON wr2.wr_reason_sk = r2_web.r_reason_sk
        FULL OUTER JOIN web_page wp_full ON wr2.wr_web_page_sk = wp_full.wp_web_page_sk
    WHERE
        NOT EXISTS (
            SELECT 1
            FROM web_page wp_chk
            WHERE wp_chk.wp_customer_sk = c2.c_customer_sk
              AND wp_chk.wp_url LIKE '%promo%'
        )
    GROUP BY
        cs2.cs_order_number,
        c2.c_customer_id,
        r2_store.r_reason_desc,
        r2_web.r_reason_desc,
        c2.c_customer_sk
)
SELECT
    order_number,
    bill_cust_id,
    ship_cust_id,
    store_ret_reason,
    web_ret_reason,
    total_sales,
    store_ret_cnt,
    web_ret_cnt,
    extra_metric,
    SUM(total_sales) OVER (PARTITION BY bill_cust_id ORDER BY order_number ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS running_total_sales
FROM union_data
ORDER BY total_sales DESC
LIMIT 100

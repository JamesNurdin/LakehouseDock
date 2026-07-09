WITH
    unified_sales AS (
        SELECT cs.cs_bill_customer_sk AS cust_sk, cs.cs_net_paid AS net_paid, d.d_date AS sale_date
        FROM catalog_sales cs
        LEFT JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
        UNION ALL
        SELECT ss.ss_customer_sk AS cust_sk, ss.ss_net_paid AS net_paid, d.d_date AS sale_date
        FROM store_sales ss
        LEFT JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
        UNION ALL
        SELECT ws.ws_bill_customer_sk AS cust_sk, ws.ws_net_paid AS net_paid, d.d_date AS sale_date
        FROM web_sales ws
        LEFT JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    ),
    cust_sales AS (
        SELECT
            cust_sk AS c_customer_sk,
            SUM(net_paid) AS total_sales,
            COUNT(*) AS total_transactions,
            MIN(sale_date) AS first_sale_date,
            MAX(sale_date) AS last_sale_date
        FROM unified_sales
        GROUP BY cust_sk
    ),
    cust_returns AS (
        SELECT
            c.c_customer_sk,
            SUM(COALESCE(sr.sr_net_loss, 0)) AS total_store_return_loss,
            SUM(COALESCE(cr.cr_net_loss, 0)) AS total_catalog_return_loss,
            SUM(COALESCE(wr.wr_net_loss, 0)) AS total_web_return_loss,
            COUNT(DISTINCT sr.sr_ticket_number) AS distinct_store_returns,
            COUNT(DISTINCT cr.cr_order_number) AS distinct_catalog_returns,
            COUNT(DISTINCT wr.wr_order_number) AS distinct_web_returns
        FROM customer c
        LEFT JOIN store_returns sr ON c.c_customer_sk = sr.sr_customer_sk
        LEFT JOIN catalog_returns cr ON c.c_customer_sk = cr.cr_returning_customer_sk
        LEFT JOIN web_returns wr ON c.c_customer_sk = wr.wr_refunded_customer_sk
        GROUP BY c.c_customer_sk
    ),
    combined AS (
        SELECT
            cs.c_customer_sk,
            COALESCE(c.c_first_name, '') || ' ' || COALESCE(c.c_last_name, '') AS full_name,
            cs.total_sales,
            cs.total_transactions,
            cr.total_store_return_loss,
            cr.total_catalog_return_loss,
            cr.total_web_return_loss,
            (COALESCE(cr.total_store_return_loss,0)
                + COALESCE(cr.total_catalog_return_loss,0)
                + COALESCE(cr.total_web_return_loss,0))
                / NULLIF(cs.total_sales,0) AS return_loss_ratio,
            CASE
                WHEN cs.total_sales IS NULL OR cs.total_sales = 0 THEN 'NO_SALES'
                WHEN (COALESCE(cr.total_store_return_loss,0)
                       + COALESCE(cr.total_catalog_return_loss,0)
                       + COALESCE(cr.total_web_return_loss,0)) > cs.total_sales * 0.5 THEN 'HIGH_LOSS'
                ELSE 'NORMAL'
            END AS loss_category,
            ROW_NUMBER() OVER (ORDER BY
                (COALESCE(cr.total_store_return_loss,0)
                 + COALESCE(cr.total_catalog_return_loss,0)
                 + COALESCE(cr.total_web_return_loss,0))
                 / NULLIF(cs.total_sales,0) DESC) AS loss_rank
        FROM cust_sales cs
        LEFT JOIN cust_returns cr ON cs.c_customer_sk = cr.c_customer_sk
        LEFT JOIN customer c ON cs.c_customer_sk = c.c_customer_sk
    ),
    top_customers AS (
        SELECT *
        FROM combined
        WHERE loss_rank <= 5 OR loss_category = 'HIGH_LOSS'
    ),
    daily_aggregates AS (
        SELECT
            d.d_date,
            SUM(COALESCE(ss.ss_net_paid,0) + COALESCE(cs.cs_net_paid,0) + COALESCE(ws.ws_net_paid,0)) AS daily_total_paid,
            SUM(COALESCE(sr.sr_net_loss,0) + COALESCE(cr.cr_net_loss,0) + COALESCE(wr.wr_net_loss,0)) AS daily_total_return_loss,
            CASE
                WHEN SUM(COALESCE(ss.ss_net_paid,0) + COALESCE(cs.cs_net_paid,0) + COALESCE(ws.ws_net_paid,0)) = 0 THEN NULL
                ELSE SUM(COALESCE(sr.sr_net_loss,0) + COALESCE(cr.cr_net_loss,0) + COALESCE(wr.wr_net_loss,0))
                     / SUM(COALESCE(ss.ss_net_paid,0) + COALESCE(cs.cs_net_paid,0) + COALESCE(ws.ws_net_paid,0))
            END AS daily_loss_ratio
        FROM date_dim d
        LEFT JOIN store_sales ss ON ss.ss_sold_date_sk = d.d_date_sk
        LEFT JOIN catalog_sales cs ON cs.cs_sold_date_sk = d.d_date_sk
        LEFT JOIN web_sales ws ON ws.ws_sold_date_sk = d.d_date_sk
        LEFT JOIN store_returns sr ON sr.sr_returned_date_sk = d.d_date_sk
        LEFT JOIN catalog_returns cr ON cr.cr_returned_date_sk = d.d_date_sk
        LEFT JOIN web_returns wr ON wr.wr_returned_date_sk = d.d_date_sk
        GROUP BY d.d_date
        HAVING SUM(COALESCE(ss.ss_net_paid,0) + COALESCE(cs.cs_net_paid,0) + COALESCE(ws.ws_net_paid,0)) > 0
    ),
    anomalous_days AS (
        SELECT *
        FROM daily_aggregates
        WHERE daily_loss_ratio > 0.4
           OR daily_total_return_loss > daily_total_paid * 0.5
           OR daily_total_paid IS NULL
    ),
    last_anomaly AS (
        SELECT d_date AS anomaly_date, daily_loss_ratio
        FROM anomalous_days
        ORDER BY d_date DESC
        LIMIT 1
    )
SELECT
    tc.c_customer_sk,
    tc.full_name,
    tc.total_sales,
    ROUND(tc.return_loss_ratio,4) AS return_loss_ratio,
    tc.loss_category,
    tc.loss_rank,
    (SELECT COUNT(*) FROM store_sales ss2 WHERE ss2.ss_customer_sk = tc.c_customer_sk AND ss2.ss_net_paid > 1000) AS high_value_store_sales_count,
    la.anomaly_date,
    da.daily_total_paid,
    da.daily_total_return_loss,
    ROUND(da.daily_loss_ratio,4) AS daily_loss_ratio,
    CONCAT(
        'Alert: Customer ',
        CAST(COALESCE(tc.c_customer_sk, -1) AS VARCHAR),
        ' flagged as ',
        COALESCE(tc.loss_category, 'UNKNOWN'),
        ' with loss ratio ',
        COALESCE(CAST(ROUND(tc.return_loss_ratio,4) AS VARCHAR), 'NULL'),
        ' on ',
        COALESCE(CAST(la.anomaly_date AS VARCHAR), 'no anomaly')
    ) AS alert_message
FROM top_customers tc
LEFT JOIN last_anomaly la ON true
LEFT JOIN daily_aggregates da ON da.d_date = la.anomaly_date
WHERE tc.c_customer_sk IS NOT NULL
UNION ALL
SELECT
    NULL AS c_customer_sk,
    'OVERALL_SUMMARY' AS full_name,
    SUM(tc.total_sales) AS total_sales,
    AVG(tc.return_loss_ratio) AS return_loss_ratio,
    NULL AS loss_category,
    NULL AS loss_rank,
    NULL AS high_value_store_sales_count,
    NULL AS anomaly_date,
    NULL AS daily_total_paid,
    NULL AS daily_total_return_loss,
    NULL AS daily_loss_ratio,
    CONCAT(
        'Overall avg return loss ratio: ',
        CAST(ROUND(AVG(tc.return_loss_ratio),4) AS VARCHAR)
    ) AS alert_message
FROM top_customers tc
WHERE tc.loss_category = 'HIGH_LOSS'

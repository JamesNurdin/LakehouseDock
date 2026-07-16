WITH sales_union AS (
    SELECT
        s.ss_sold_date_sk AS date_sk,
        s.ss_customer_sk AS customer_sk,
        s.ss_net_paid AS net_paid,
        s.ss_quantity AS quantity,
        'store' AS sales_channel
    FROM store_sales s
    UNION ALL
    SELECT
        cs.cs_sold_date_sk,
        cs.cs_bill_customer_sk,
        cs.cs_net_paid,
        cs.cs_quantity,
        'catalog'
    FROM catalog_sales cs
    UNION ALL
    SELECT
        ws.ws_sold_date_sk,
        ws.ws_bill_customer_sk,
        ws.ws_net_paid,
        ws.ws_quantity,
        'web'
    FROM web_sales ws
),
customer_daily_sales AS (
    SELECT
        su.date_sk,
        su.customer_sk,
        SUM(su.net_paid) AS total_net_paid,
        SUM(su.quantity) AS total_quantity,
        COUNT(*) AS transaction_count,
        COUNT(DISTINCT su.sales_channel) AS channel_count
    FROM sales_union su
    GROUP BY su.date_sk, su.customer_sk
),
ranked_daily AS (
    SELECT
        cds.*,
        ROW_NUMBER() OVER (PARTITION BY cds.date_sk ORDER BY cds.total_net_paid DESC) AS rn,
        SUM(cds.total_net_paid) OVER (PARTITION BY cds.date_sk) AS daily_total_net_paid
    FROM customer_daily_sales cds
),
top_customers AS (
    SELECT
        rd.date_sk,
        rd.customer_sk,
        rd.total_net_paid,
        rd.total_quantity,
        rd.transaction_count,
        rd.channel_count,
        rd.daily_total_net_paid,
        d.d_date,
        c.c_first_name,
        c.c_last_name,
        COALESCE(c.c_preferred_cust_flag, 'N') AS pref_cust_flag,
        CASE
            WHEN c.c_email_address LIKE '%@%' THEN split_part(c.c_email_address, '@', 2)
            ELSE NULL
        END AS email_domain
    FROM ranked_daily rd
    LEFT JOIN date_dim d ON rd.date_sk = d.d_date_sk
    LEFT JOIN customer c ON rd.customer_sk = c.c_customer_sk
    WHERE rd.rn <= 5
),
customer_return_summary AS (
    SELECT
        sr.sr_customer_sk AS customer_sk,
        sr.sr_returned_date_sk AS return_date_sk,
        SUM(sr.sr_net_loss) AS total_return_loss,
        COUNT(*) AS return_count
    FROM store_returns sr
    GROUP BY sr.sr_customer_sk, sr.sr_returned_date_sk
),
call_center_sales_agg AS (
    SELECT
        SUM(cc_total) AS total_cc_sales
    FROM (
        SELECT
            cc.cc_call_center_sk,
            SUM(cs.cs_net_paid) AS cc_total
        FROM call_center cc
        LEFT JOIN catalog_sales cs ON cc.cc_call_center_sk = cs.cs_call_center_sk
        GROUP BY cc.cc_call_center_sk
    )
),
combined_sales AS (
    SELECT
        tc.date_sk,
        tc.customer_sk,
        tc.total_net_paid,
        tc.total_quantity,
        tc.transaction_count,
        tc.channel_count,
        tc.daily_total_net_paid,
        tc.d_date,
        COALESCE(tc.c_first_name, 'Unknown') AS first_name,
        COALESCE(tc.c_last_name, 'Unknown') AS last_name,
        tc.pref_cust_flag,
        tc.email_domain,
        COALESCE(crs.total_return_loss, 0) AS total_return_loss,
        COALESCE(crs.return_count, 0) AS return_count,
        CASE
            WHEN tc.total_net_paid IS NULL THEN 0
            ELSE tc.total_net_paid - COALESCE(crs.total_return_loss, 0)
        END AS adjusted_net_paid,
        COALESCE(cc.total_cc_sales, 0) AS cc_sales,
        CONCAT('Cust-', CAST(tc.customer_sk AS varchar), '-', COALESCE(tc.email_domain, 'nodomain')) AS customer_key,
        (SELECT COUNT(DISTINCT su.sales_channel) FROM sales_union su WHERE su.customer_sk = tc.customer_sk) AS distinct_channels_used,
        ROW_NUMBER() OVER (PARTITION BY tc.date_sk ORDER BY tc.total_net_paid DESC) AS final_rank
    FROM top_customers tc
    LEFT JOIN customer_return_summary crs
        ON tc.customer_sk = crs.customer_sk AND tc.date_sk = crs.return_date_sk
    LEFT JOIN call_center_sales_agg cc
        ON TRUE
    WHERE (tc.total_net_paid > 0 OR tc.total_quantity > 0)
      AND (tc.pref_cust_flag = 'Y' OR tc.pref_cust_flag = 'N')
      AND tc.email_domain IS NOT NULL
),
customers_without_sales AS (
    SELECT
        NULL AS date_sk,
        c.c_customer_sk AS customer_sk,
        0 AS total_net_paid,
        0 AS total_quantity,
        0 AS transaction_count,
        0 AS channel_count,
        0 AS daily_total_net_paid,
        NULL AS d_date,
        COALESCE(c.c_first_name, 'Unknown') AS first_name,
        COALESCE(c.c_last_name, 'Unknown') AS last_name,
        COALESCE(c.c_preferred_cust_flag, 'N') AS pref_cust_flag,
        NULL AS email_domain,
        0 AS total_return_loss,
        0 AS return_count,
        0 AS adjusted_net_paid,
        0 AS cc_sales,
        CONCAT('NoSale-', CAST(c.c_customer_sk AS varchar)) AS customer_key,
        0 AS distinct_channels_used,
        NULL AS final_rank
    FROM customer c
    WHERE NOT EXISTS (
        SELECT 1 FROM sales_union su WHERE su.customer_sk = c.c_customer_sk
    )
),
final_result AS (
    SELECT *
    FROM combined_sales
    WHERE adjusted_net_paid / NULLIF(total_net_paid, 0) < 0.5
    UNION ALL
    SELECT *
    FROM customers_without_sales
)
SELECT *
FROM final_result
ORDER BY d_date DESC NULLS LAST, adjusted_net_paid DESC
LIMIT 200

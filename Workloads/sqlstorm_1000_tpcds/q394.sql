WITH
sales_agg AS (
    SELECT
        c.c_customer_sk,
        COALESCE(c.c_first_name, '') || ' ' || COALESCE(c.c_last_name, '') AS cust_name,
        COALESCE(cs.total_cs_net_paid, 0) + COALESCE(ss.total_ss_net_paid, 0) + COALESCE(ws.total_ws_net_paid, 0) AS total_net_paid,
        COALESCE(cs.distinct_call_centers, 0) AS distinct_call_centers,
        COALESCE(cs.max_cs_date_sk, 0) AS max_cs_date_sk,
        COALESCE(ss.max_ss_date_sk, 0) AS max_ss_date_sk,
        COALESCE(ws.max_ws_date_sk, 0) AS max_ws_date_sk
    FROM customer c
    LEFT JOIN (
        SELECT
            cs_bill_customer_sk AS cust_sk,
            SUM(cs_net_paid) AS total_cs_net_paid,
            COUNT(DISTINCT cs_call_center_sk) AS distinct_call_centers,
            MAX(cs_sold_date_sk) AS max_cs_date_sk
        FROM catalog_sales
        GROUP BY cs_bill_customer_sk
    ) cs ON cs.cust_sk = c.c_customer_sk
    LEFT JOIN (
        SELECT
            ss_customer_sk AS cust_sk,
            SUM(ss_net_paid) AS total_ss_net_paid,
            MAX(ss_sold_date_sk) AS max_ss_date_sk
        FROM store_sales
        GROUP BY ss_customer_sk
    ) ss ON ss.cust_sk = c.c_customer_sk
    LEFT JOIN (
        SELECT
            ws_bill_customer_sk AS cust_sk,
            SUM(ws_net_paid) AS total_ws_net_paid,
            MAX(ws_sold_date_sk) AS max_ws_date_sk
        FROM web_sales
        GROUP BY ws_bill_customer_sk
    ) ws ON ws.cust_sk = c.c_customer_sk
),
returns_agg AS (
    SELECT
        ret.cust_sk,
        SUM(ret.return_amount) AS total_return_amount,
        MAX(ret.returned_date_sk) AS max_return_date_sk
    FROM (
        SELECT
            cr_returning_customer_sk AS cust_sk,
            cr_return_amount AS return_amount,
            cr_returned_date_sk AS returned_date_sk
        FROM catalog_returns
        UNION ALL
        SELECT
            sr_customer_sk AS cust_sk,
            sr_return_amt AS return_amount,
            sr_returned_date_sk AS returned_date_sk
        FROM store_returns
        UNION ALL
        SELECT
            wr_refunded_customer_sk AS cust_sk,
            wr_return_amt AS return_amount,
            wr_returned_date_sk AS returned_date_sk
        FROM web_returns
    ) ret
    GROUP BY ret.cust_sk
),
latest_dates AS (
    SELECT
        sa.c_customer_sk,
        GREATEST(
            sa.max_cs_date_sk,
            sa.max_ss_date_sk,
            sa.max_ws_date_sk
        ) AS latest_sales_date_sk
    FROM sales_agg sa
),
final AS (
    SELECT
        sa.c_customer_sk,
        sa.cust_name,
        sa.total_net_paid,
        COALESCE(ra.total_return_amount, 0) AS total_return_amount,
        (sa.total_net_paid - COALESCE(ra.total_return_amount, 0)) AS net_after_returns,
        ld.latest_sales_date_sk,
        COALESCE(ra.max_return_date_sk, 0) AS latest_return_date_sk,
        sa.distinct_call_centers,
        ROW_NUMBER() OVER (ORDER BY (sa.total_net_paid - COALESCE(ra.total_return_amount, 0)) DESC) AS rn
    FROM sales_agg sa
    LEFT JOIN returns_agg ra ON ra.cust_sk = sa.c_customer_sk
    LEFT JOIN latest_dates ld ON ld.c_customer_sk = sa.c_customer_sk
    WHERE (sa.total_net_paid - COALESCE(ra.total_return_amount, 0)) > 0
      AND (sa.cust_name LIKE '%Smith%' OR sa.cust_name LIKE '%Johnson%')
)
SELECT
    f.rn,
    f.c_customer_sk,
    f.cust_name,
    f.total_net_paid,
    f.total_return_amount,
    f.net_after_returns,
    COALESCE(
        (SELECT d.d_date FROM date_dim d WHERE d.d_date_sk = f.latest_sales_date_sk),
        DATE '1900-01-01'
    ) AS latest_sales_date,
    COALESCE(
        (SELECT d.d_date FROM date_dim d WHERE d.d_date_sk = f.latest_return_date_sk),
        DATE '1900-01-01'
    ) AS latest_return_date,
    CASE
        WHEN f.distinct_call_centers = 0 THEN 'No Call Center'
        WHEN f.distinct_call_centers = 1 THEN 'Single Call Center'
        ELSE CAST(f.distinct_call_centers AS VARCHAR) || ' Call Centers'
    END AS call_center_info
FROM final f
WHERE f.rn <= 100
ORDER BY f.net_after_returns DESC, f.rn

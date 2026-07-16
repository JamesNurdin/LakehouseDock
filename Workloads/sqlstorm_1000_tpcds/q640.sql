WITH
store_agg AS (
    SELECT
        ss.ss_customer_sk AS customer_sk,
        SUM(ss.ss_net_paid_inc_tax) AS store_net_paid,
        SUM(ss.ss_net_profit) AS store_net_profit,
        COUNT(DISTINCT ss.ss_ticket_number) AS store_txn_count,
        MAX(ss.ss_sold_date_sk) AS store_last_date_sk
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    WHERE d.d_year BETWEEN year(DATE '2024-10-01') - 1 AND year(DATE '2024-10-01')
    GROUP BY ss.ss_customer_sk
),
catalog_agg AS (
    SELECT
        cs.cs_bill_customer_sk AS customer_sk,
        SUM(cs.cs_net_paid_inc_tax) AS catalog_net_paid,
        SUM(cs.cs_net_profit) AS catalog_net_profit,
        COUNT(DISTINCT cs.cs_order_number) AS catalog_txn_count,
        MAX(cs.cs_sold_date_sk) AS catalog_last_date_sk
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    WHERE d.d_year BETWEEN year(DATE '2024-10-01') - 1 AND year(DATE '2024-10-01')
    GROUP BY cs.cs_bill_customer_sk
),
web_agg AS (
    SELECT
        ws.ws_bill_customer_sk AS customer_sk,
        SUM(ws.ws_net_paid_inc_tax) AS web_net_paid,
        SUM(ws.ws_net_profit) AS web_net_profit,
        COUNT(DISTINCT ws.ws_order_number) AS web_txn_count,
        MAX(ws.ws_sold_date_sk) AS web_last_date_sk
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE d.d_year BETWEEN year(DATE '2024-10-01') - 1 AND year(DATE '2024-10-01')
    GROUP BY ws.ws_bill_customer_sk
),
customer_info AS (
    SELECT
        c.c_customer_sk AS customer_sk,
        concat_ws(' ', c.c_first_name, c.c_last_name) AS full_name,
        COALESCE(cd.cd_gender, 'U') AS gender,
        cd.cd_education_status AS education_status,
        cd.cd_credit_rating AS credit_rating,
        ca.ca_state AS state,
        ca.ca_city AS city,
        COALESCE(c.c_preferred_cust_flag, 'N') AS pref_cust_flag
    FROM customer c
    LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
),
overall_totals AS (
    SELECT
        ci.customer_sk,
        ci.full_name,
        ci.gender,
        ci.education_status,
        ci.credit_rating,
        ci.state,
        ci.city,
        ci.pref_cust_flag,
        COALESCE(sa.store_net_paid, 0) + COALESCE(ca.catalog_net_paid, 0) + COALESCE(wa.web_net_paid, 0) AS total_net_paid,
        COALESCE(sa.store_net_profit, 0) + COALESCE(ca.catalog_net_profit, 0) + COALESCE(wa.web_net_profit, 0) AS total_net_profit,
        COALESCE(sa.store_txn_count, 0) + COALESCE(ca.catalog_txn_count, 0) + COALESCE(wa.web_txn_count, 0) AS total_txn_count,
        GREATEST(
            COALESCE(sa.store_last_date_sk, 0),
            COALESCE(ca.catalog_last_date_sk, 0),
            COALESCE(wa.web_last_date_sk, 0)
        ) AS most_recent_date_sk,
        ROW_NUMBER() OVER (ORDER BY (COALESCE(sa.store_net_profit, 0) + COALESCE(ca.catalog_net_profit, 0) + COALESCE(wa.web_net_profit, 0)) DESC) AS profit_rank
    FROM customer_info ci
    LEFT JOIN store_agg sa ON ci.customer_sk = sa.customer_sk
    LEFT JOIN catalog_agg ca ON ci.customer_sk = ca.customer_sk
    LEFT JOIN web_agg wa ON ci.customer_sk = wa.customer_sk
),
latest_store_order AS (
    SELECT
        ss.ss_customer_sk,
        ss.ss_ticket_number,
        ss.ss_sold_date_sk
    FROM store_sales ss
    WHERE ss.ss_sold_date_sk = (
        SELECT MAX(ss2.ss_sold_date_sk)
        FROM store_sales ss2
        WHERE ss2.ss_customer_sk = ss.ss_customer_sk
    )
),
high_store_returns AS (
    SELECT
        sr.sr_customer_sk AS customer_sk,
        SUM(sr.sr_net_loss) AS total_return_loss,
        CAST('Store Return' AS varchar) AS return_type
    FROM store_returns sr
    JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
    WHERE d.d_year = year(DATE '2024-10-01') - 1
    GROUP BY sr.sr_customer_sk
    HAVING SUM(sr.sr_net_loss) > 5000
),
high_web_returns AS (
    SELECT
        wr.wr_refunded_customer_sk AS customer_sk,
        SUM(wr.wr_net_loss) AS total_return_loss,
        CAST('Web Return' AS varchar) AS return_type
    FROM web_returns wr
    JOIN date_dim d ON wr.wr_returned_date_sk = d.d_date_sk
    WHERE d.d_year = year(DATE '2024-10-01') - 1
    GROUP BY wr.wr_refunded_customer_sk
    HAVING SUM(wr.wr_net_loss) > 5000
)
SELECT
    ot.customer_sk,
    ot.full_name,
    ot.gender,
    ot.education_status,
    ot.credit_rating,
    ot.state,
    ot.city,
    ot.pref_cust_flag,
    ot.total_net_paid,
    ot.total_net_profit,
    ot.total_txn_count,
    d.d_date AS most_recent_date,
    ot.profit_rank,
    COALESCE(ls.ss_ticket_number, -1) AS latest_store_ticket,
    ls.ss_sold_date_sk AS latest_store_sold_date_sk,
    CAST(NULL AS decimal(15,2)) AS extra_metric,
    CAST(NULL AS varchar) AS return_type
FROM overall_totals ot
LEFT JOIN latest_store_order ls ON ot.customer_sk = ls.ss_customer_sk
LEFT JOIN date_dim d ON ot.most_recent_date_sk = d.d_date_sk
WHERE ot.profit_rank <= 10

UNION ALL

SELECT
    rc.customer_sk,
    concat('ReturnCustomer_', CAST(rc.customer_sk AS varchar)) AS full_name,
    CAST(NULL AS varchar) AS gender,
    CAST(NULL AS varchar) AS education_status,
    CAST(NULL AS varchar) AS credit_rating,
    CAST(NULL AS varchar) AS state,
    CAST(NULL AS varchar) AS city,
    CAST(NULL AS varchar) AS pref_cust_flag,
    CAST(0 AS decimal(15,2)) AS total_net_paid,
    CAST(0 AS decimal(15,2)) AS total_net_profit,
    0 AS total_txn_count,
    CAST(NULL AS date) AS most_recent_date,
    CAST(NULL AS bigint) AS profit_rank,
    CAST(NULL AS integer) AS latest_store_ticket,
    CAST(NULL AS integer) AS latest_store_sold_date_sk,
    CAST(rc.total_return_loss AS decimal(15,2)) AS extra_metric,
    rc.return_type
FROM (
    SELECT * FROM high_store_returns
    UNION ALL
    SELECT * FROM high_web_returns
) rc
ORDER BY profit_rank ASC NULLS LAST, extra_metric DESC

WITH
store_sales_agg AS (
    SELECT
        ss.ss_customer_sk AS customer_sk,
        DATE_TRUNC('quarter', dd.d_date) AS quarter_start,
        SUM(ss.ss_net_paid) AS store_net_paid,
        SUM(COALESCE(sr.sr_net_loss, 0)) AS store_return_loss
    FROM store_sales ss
    JOIN date_dim dd ON dd.d_date_sk = ss.ss_sold_date_sk
    LEFT JOIN store_returns sr
        ON sr.sr_customer_sk = ss.ss_customer_sk
        AND sr.sr_returned_date_sk = ss.ss_sold_date_sk
    GROUP BY ss.ss_customer_sk, DATE_TRUNC('quarter', dd.d_date)
),
catalog_sales_agg AS (
    SELECT
        cs.cs_bill_customer_sk AS customer_sk,
        DATE_TRUNC('quarter', dd.d_date) AS quarter_start,
        SUM(cs.cs_net_paid) AS catalog_net_paid,
        SUM(COALESCE(cr.cr_net_loss, 0)) AS catalog_return_loss
    FROM catalog_sales cs
    JOIN date_dim dd ON dd.d_date_sk = cs.cs_sold_date_sk
    LEFT JOIN catalog_returns cr
        ON cr.cr_returning_customer_sk = cs.cs_bill_customer_sk
        AND cr.cr_returned_date_sk = cs.cs_sold_date_sk
    GROUP BY cs.cs_bill_customer_sk, DATE_TRUNC('quarter', dd.d_date)
),
web_sales_agg AS (
    SELECT
        ws.ws_bill_customer_sk AS customer_sk,
        DATE_TRUNC('quarter', dd.d_date) AS quarter_start,
        SUM(ws.ws_net_paid) AS web_net_paid,
        SUM(COALESCE(wr.wr_net_loss, 0)) AS web_return_loss
    FROM web_sales ws
    JOIN date_dim dd ON dd.d_date_sk = ws.ws_sold_date_sk
    LEFT JOIN web_returns wr
        ON wr.wr_returning_customer_sk = ws.ws_bill_customer_sk
        AND wr.wr_returned_date_sk = ws.ws_sold_date_sk
    GROUP BY ws.ws_bill_customer_sk, DATE_TRUNC('quarter', dd.d_date)
),
combined_sales AS (
    SELECT
        COALESCE(s.customer_sk, c.customer_sk, w.customer_sk) AS customer_sk,
        COALESCE(s.quarter_start, c.quarter_start, w.quarter_start) AS quarter_start,
        COALESCE(s.store_net_paid, 0) - COALESCE(s.store_return_loss, 0) AS store_net,
        COALESCE(c.catalog_net_paid, 0) - COALESCE(c.catalog_return_loss, 0) AS catalog_net,
        COALESCE(w.web_net_paid, 0) - COALESCE(w.web_return_loss, 0) AS web_net
    FROM store_sales_agg s
    FULL OUTER JOIN catalog_sales_agg c
        ON s.customer_sk = c.customer_sk AND s.quarter_start = c.quarter_start
    FULL OUTER JOIN web_sales_agg w
        ON COALESCE(s.customer_sk, c.customer_sk) = w.customer_sk
        AND COALESCE(s.quarter_start, c.quarter_start) = w.quarter_start
),
total_net_per_quarter AS (
    SELECT
        customer_sk,
        quarter_start,
        (store_net + catalog_net + web_net) AS total_net,
        ROW_NUMBER() OVER (PARTITION BY quarter_start ORDER BY (store_net + catalog_net + web_net) DESC) AS revenue_rank
    FROM combined_sales
),
customer_latest_purchase AS (
    SELECT
        c.c_customer_sk,
        MAX(dd.d_date) AS latest_purchase_date
    FROM (
        SELECT ss_customer_sk AS cust_sk, ss_sold_date_sk AS date_sk FROM store_sales
        UNION ALL
        SELECT cs_bill_customer_sk, cs_sold_date_sk FROM catalog_sales
        UNION ALL
        SELECT ws_bill_customer_sk, ws_sold_date_sk FROM web_sales
    ) sp
    JOIN date_dim dd ON dd.d_date_sk = sp.date_sk
    JOIN customer c ON c.c_customer_sk = sp.cust_sk
    GROUP BY c.c_customer_sk
),
customer_demo AS (
    SELECT
        cd_demo_sk,
        cd_gender,
        cd_marital_status,
        cd_education_status,
        cd_credit_rating
    FROM customer_demographics
),
final_result AS (
    SELECT
        tn.customer_sk,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS customer_name,
        tn.quarter_start,
        tn.total_net,
        tn.revenue_rank,
        COALESCE(cd.cd_gender, 'U') AS gender,
        COALESCE(cd.cd_marital_status, 'U') AS marital_status,
        CASE
            WHEN tn.revenue_rank <= 10 THEN 'Elite'
            WHEN tn.revenue_rank <= 100 THEN 'Prime'
            ELSE 'Standard'
        END AS segment,
        COALESCE(clp.latest_purchase_date, DATE '1900-01-01') AS latest_purchase_date,
        CASE
            WHEN EXISTS (
                SELECT 1
                FROM store_returns sr
                WHERE sr.sr_customer_sk = tn.customer_sk
                  AND DATE_TRUNC('quarter',
                      (SELECT d_date FROM date_dim WHERE d_date_sk = sr.sr_returned_date_sk)
                  ) = tn.quarter_start
            ) THEN 'HasReturnInQuarter'
            ELSE 'NoReturnInQuarter'
        END AS return_flag
    FROM total_net_per_quarter tn
    LEFT JOIN customer c ON c.c_customer_sk = tn.customer_sk
    LEFT JOIN customer_demo cd ON cd.cd_demo_sk = c.c_current_cdemo_sk
    LEFT JOIN customer_latest_purchase clp ON clp.c_customer_sk = tn.customer_sk
    WHERE tn.revenue_rank <= 100
)
SELECT *
FROM final_result
ORDER BY revenue_rank, customer_sk

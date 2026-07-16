WITH seq AS (
    SELECT n
    FROM UNNEST(sequence(1, 10)) AS t(n)
),
sales_union AS (
    SELECT cs.cs_bill_customer_sk AS customer_sk,
           cs.cs_sold_date_sk AS date_sk,
           cs.cs_net_paid AS net_paid,
           cs.cs_net_profit AS net_profit,
           cs.cs_ext_discount_amt AS discount_amt
    FROM catalog_sales cs
    UNION ALL
    SELECT ss.ss_customer_sk,
           ss.ss_sold_date_sk,
           ss.ss_net_paid,
           ss.ss_net_profit,
           ss.ss_ext_discount_amt
    FROM store_sales ss
    UNION ALL
    SELECT ws.ws_bill_customer_sk,
           ws.ws_sold_date_sk,
           ws.ws_net_paid,
           ws.ws_net_profit,
           ws.ws_ext_discount_amt
    FROM web_sales ws
),
customer_last_txn AS (
    SELECT
        su.customer_sk AS cust_sk,
        MAX(d.d_date) AS last_txn_date
    FROM sales_union su
    JOIN date_dim d ON su.date_sk = d.d_date_sk
    GROUP BY su.customer_sk
),
aggregated AS (
    SELECT
        c.c_customer_sk,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS customer_name,
        COALESCE(c.c_preferred_cust_flag, 'N') AS pref_flag,
        d.d_year,
        SUM(su.net_paid) AS total_net_paid,
        SUM(su.net_profit) AS total_net_profit,
        AVG(su.discount_amt) AS avg_discount,
        MAX(clt.last_txn_date) AS last_txn_date,
        COUNT(*) AS txn_count
    FROM sales_union su
    LEFT JOIN date_dim d ON su.date_sk = d.d_date_sk
    LEFT JOIN customer c ON su.customer_sk = c.c_customer_sk
    LEFT JOIN customer_last_txn clt ON c.c_customer_sk = clt.cust_sk
    WHERE (c.c_preferred_cust_flag = 'Y' OR c.c_preferred_cust_flag IS NULL)
      AND d.d_year BETWEEN 2000 AND 2002
    GROUP BY
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        c.c_preferred_cust_flag,
        d.d_year
),
ranked AS (
    SELECT
        a.*,
        ROW_NUMBER() OVER (PARTITION BY a.d_year ORDER BY a.total_net_paid DESC) AS sales_rank,
        CASE
            WHEN a.total_net_paid IS NULL THEN 0
            ELSE a.total_net_paid
        END AS net_paid_coalesced
    FROM aggregated a
),
final AS (
    SELECT
        r.c_customer_sk,
        r.customer_name,
        r.pref_flag,
        r.d_year,
        r.total_net_paid,
        r.total_net_profit,
        r.avg_discount,
        r.last_txn_date,
        r.txn_count,
        r.sales_rank,
        r.net_paid_coalesced,
        (
            SELECT MAX(a2.total_net_profit)
            FROM aggregated a2
            WHERE a2.c_customer_sk = r.c_customer_sk
        ) AS max_profit_any_year
    FROM ranked r
    WHERE r.sales_rank <= (SELECT n FROM seq WHERE n = 5)
)
SELECT *
FROM final
ORDER BY d_year, total_net_paid DESC
LIMIT 100

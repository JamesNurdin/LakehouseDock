WITH base AS (
    SELECT
        c.c_customer_sk,
        c.c_email_address,
        d.d_year,
        ss.ss_ext_sales_price,
        ss.ss_ticket_number,
        ed.email_domain
    FROM store_sales ss
    JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    CROSS JOIN LATERAL (
        SELECT regexp_extract(c.c_email_address, '@(.*)$') AS email_domain
    ) ed
    WHERE regexp_like(c.c_email_address, '@example\\.com$')
      AND c.c_last_name LIKE 'S%'
),

agg AS (
    SELECT
        b.c_customer_sk,
        b.c_email_address,
        b.email_domain,
        b.d_year,
        SUM(b.ss_ext_sales_price) AS yearly_sales,
        COUNT(*) AS txn_cnt
    FROM base b
    GROUP BY b.c_customer_sk, b.c_email_address, b.email_domain, b.d_year
),

lagged AS (
    SELECT
        a.c_customer_sk,
        a.c_email_address,
        a.email_domain,
        a.d_year,
        a.yearly_sales,
        a.txn_cnt,
        LAG(a.yearly_sales) OVER (PARTITION BY a.c_customer_sk ORDER BY a.d_year) AS prev_year_sales,
        a.yearly_sales - COALESCE(LAG(a.yearly_sales) OVER (PARTITION BY a.c_customer_sk ORDER BY a.d_year), 0) AS sales_change
    FROM agg a
),

returns AS (
    SELECT
        r.sr_customer_sk,
        d.d_year,
        SUM(r.sr_return_amt_inc_tax) AS total_return_amount,
        COUNT(*) AS return_cnt
    FROM store_returns r
    JOIN date_dim d ON r.sr_returned_date_sk = d.d_date_sk
    WHERE r.sr_reason_sk IN (3, 19, 24)
    GROUP BY r.sr_customer_sk, d.d_year
),

final_union AS (
    SELECT
        l.c_customer_sk,
        l.c_email_address,
        l.email_domain,
        substring(l.email_domain, 1, 5) AS domain_prefix,
        l.d_year,
        l.yearly_sales,
        l.prev_year_sales,
        l.sales_change,
        COALESCE(r.total_return_amount, 0) AS total_return_amount,
        COALESCE(r.return_cnt, 0) AS return_cnt
    FROM lagged l
    LEFT JOIN returns r ON l.c_customer_sk = r.sr_customer_sk AND l.d_year = r.d_year
    WHERE l.sales_change > 0

    UNION

    SELECT
        l.c_customer_sk,
        l.c_email_address,
        l.email_domain,
        substring(l.email_domain, 1, 5) AS domain_prefix,
        l.d_year,
        l.yearly_sales,
        l.prev_year_sales,
        l.sales_change,
        COALESCE(r.total_return_amount, 0) AS total_return_amount,
        COALESCE(r.return_cnt, 0) AS return_cnt
    FROM lagged l
    LEFT JOIN returns r ON l.c_customer_sk = r.sr_customer_sk AND l.d_year = r.d_year
    WHERE l.sales_change <= 0
),

except_set AS (
    SELECT
        c.c_customer_sk,
        c.c_email_address,
        CAST(NULL AS varchar) AS email_domain,
        CAST(NULL AS varchar) AS domain_prefix,
        d.d_year,
        0 AS yearly_sales,
        NULL AS prev_year_sales,
        NULL AS sales_change,
        0 AS total_return_amount,
        0 AS return_cnt
    FROM customer c
    JOIN date_dim d ON c.c_first_sales_date_sk = d.d_date_sk
    WHERE regexp_extract(c.c_email_address, '^(.*)@') = 'test'
)

SELECT *
FROM final_union
EXCEPT
SELECT *
FROM except_set
ORDER BY d_year DESC, yearly_sales DESC
OFFSET 0 FETCH NEXT 100 ROWS ONLY

WITH
    customer_store AS (
        SELECT sr_customer_sk AS c_customer_sk,
               sr_store_sk
        FROM store_returns
        GROUP BY sr_customer_sk, sr_store_sk
    ),
    filtered_customers AS (
        SELECT c.c_customer_sk,
               c.c_first_name,
               c.c_last_name,
               c.c_email_address,
               csmap.sr_store_sk
        FROM customer c
        JOIN customer_store csmap ON c.c_customer_sk = csmap.c_customer_sk
        WHERE regexp_like(c.c_email_address, '@.*corp\\.com$')
          AND substring(c.c_first_name, 1, 1) = 'A'
    ),
    store_info AS (
        SELECT s.s_store_sk,
               s.s_store_id,
               s.s_store_name
        FROM store s
        WHERE s.s_store_name LIKE '%Market%'
    ),
    sales_agg AS (
        SELECT
            si.s_store_id,
            si.s_store_name,
            sum(cs.cs_net_paid) AS total_sales,
            max(concat_ws(' ', fc.c_first_name, fc.c_last_name)) AS sample_customer_name,
            max(regexp_extract(fc.c_email_address, '@([^@]+)$', 1)) AS sample_email_domain
        FROM catalog_sales cs
        JOIN filtered_customers fc ON cs.cs_bill_customer_sk = fc.c_customer_sk
        JOIN store_info si ON fc.sr_store_sk = si.s_store_sk
        GROUP BY si.s_store_id, si.s_store_name
    ),
    returns_agg AS (
        SELECT
            si.s_store_id,
            si.s_store_name,
            sum(sr.sr_return_amt) AS total_returns
        FROM store_returns sr
        JOIN filtered_customers fc ON sr.sr_customer_sk = fc.c_customer_sk
        JOIN store_info si ON sr.sr_store_sk = si.s_store_sk
        GROUP BY si.s_store_id, si.s_store_name
    )
SELECT
    s.s_store_id,
    s.s_store_name,
    s.total_sales,
    r.total_returns,
    s.total_sales - coalesce(r.total_returns, 0) AS net_sales,
    s.sample_customer_name,
    s.sample_email_domain,
    ROW_NUMBER() OVER (ORDER BY (s.total_sales - coalesce(r.total_returns, 0)) DESC) AS sales_rank
FROM sales_agg s
LEFT JOIN returns_agg r
    ON s.s_store_id = r.s_store_id
   AND s.s_store_name = r.s_store_name
ORDER BY net_sales DESC
LIMIT 100

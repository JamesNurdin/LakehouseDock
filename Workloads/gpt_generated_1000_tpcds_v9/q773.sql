WITH catalog_summary AS (
    SELECT
        c.c_customer_id AS customer_id,
        c.c_customer_sk AS customer_sk,
        concat(c.c_first_name, ' ', c.c_last_name) AS customer_name,
        'catalog' AS channel,
        SUM(cs.cs_net_paid_inc_tax) AS total_sales_amount,
        SUM(cs.cs_quantity) AS total_quantity,
        latest.cs_sold_date_sk AS latest_sold_date_sk,
        COUNT(DISTINCT cs.cs_catalog_page_sk) AS distinct_pages,
        MAX(cs.cs_net_paid_inc_tax) AS max_catalog_sale
    FROM catalog_sales cs
    JOIN customer c
        ON cs.cs_bill_customer_sk = c.c_customer_sk
    JOIN catalog_page cp
        ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    CROSS JOIN LATERAL (
        SELECT cs_inner.cs_sold_date_sk
        FROM catalog_sales cs_inner
        WHERE cs_inner.cs_bill_customer_sk = c.c_customer_sk
        ORDER BY cs_inner.cs_sold_date_sk DESC
        LIMIT 1
    ) latest
    WHERE cp.cp_type = 'Electronic'
    GROUP BY
        c.c_customer_id,
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        latest.cs_sold_date_sk
),
store_summary AS (
    SELECT
        c.c_customer_id AS customer_id,
        c.c_customer_sk AS customer_sk,
        concat(c.c_first_name, ' ', c.c_last_name) AS customer_name,
        'store' AS channel,
        SUM(ss.ss_net_paid_inc_tax) AS total_sales_amount,
        SUM(ss.ss_quantity) AS total_quantity,
        latest.ss_sold_date_sk AS latest_sold_date_sk,
        CAST(NULL AS BIGINT) AS distinct_pages,
        CAST(NULL AS decimal(7,2)) AS max_catalog_sale
    FROM store_sales ss
    JOIN customer c
        ON ss.ss_customer_sk = c.c_customer_sk
    JOIN store s
        ON ss.ss_store_sk = s.s_store_sk
    CROSS JOIN LATERAL (
        SELECT ss_inner.ss_sold_date_sk
        FROM store_sales ss_inner
        WHERE ss_inner.ss_customer_sk = c.c_customer_sk
        ORDER BY ss_inner.ss_sold_date_sk DESC
        LIMIT 1
    ) latest
    WHERE s.s_state = 'CA'
    GROUP BY
        c.c_customer_id,
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        latest.ss_sold_date_sk
),
combined AS (
    SELECT * FROM catalog_summary
    UNION ALL
    SELECT * FROM store_summary
)
SELECT
    combined.customer_id,
    combined.customer_name,
    combined.channel,
    combined.total_sales_amount,
    combined.total_quantity,
    combined.latest_sold_date_sk,
    combined.distinct_pages,
    combined.max_catalog_sale,
    (
        SELECT COUNT(*)
        FROM catalog_returns cr
        WHERE cr.cr_refunded_customer_sk = combined.customer_sk
    ) AS return_count
FROM combined
WHERE combined.total_sales_amount > (
    SELECT AVG(inner_combined.total_sales_amount)
    FROM combined inner_combined
    WHERE inner_combined.channel = combined.channel
)
ORDER BY combined.total_sales_amount DESC
LIMIT 100

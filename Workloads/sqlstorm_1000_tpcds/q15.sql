WITH sales_union AS (
    SELECT cs.cs_sold_date_sk AS sold_date_sk,
           cs.cs_bill_customer_sk AS customer_sk,
           cs.cs_item_sk AS item_sk,
           cs.cs_quantity AS quantity,
           cs.cs_net_paid AS net_paid,
           'catalog' AS channel
    FROM catalog_sales cs
    UNION ALL
    SELECT ss.ss_sold_date_sk AS sold_date_sk,
           ss.ss_customer_sk AS customer_sk,
           ss.ss_item_sk AS item_sk,
           ss.ss_quantity AS quantity,
           ss.ss_net_paid AS net_paid,
           'store' AS channel
    FROM store_sales ss
    UNION ALL
    SELECT ws.ws_sold_date_sk AS sold_date_sk,
           ws.ws_bill_customer_sk AS customer_sk,
           ws.ws_item_sk AS item_sk,
           ws.ws_quantity AS quantity,
           ws.ws_net_paid AS net_paid,
           'web' AS channel
    FROM web_sales ws
), returns_union AS (
    SELECT cr.cr_returned_date_sk AS returned_date_sk,
           cr.cr_refunded_customer_sk AS customer_sk,
           cr.cr_item_sk AS item_sk,
           cr.cr_return_quantity AS quantity,
           cr.cr_return_amount AS return_amount,
           'catalog' AS channel
    FROM catalog_returns cr
    UNION ALL
    SELECT sr.sr_returned_date_sk AS returned_date_sk,
           sr.sr_customer_sk AS customer_sk,
           sr.sr_item_sk AS item_sk,
           sr.sr_return_quantity AS quantity,
           sr.sr_return_amt AS return_amount,
           'store' AS channel
    FROM store_returns sr
    UNION ALL
    SELECT wr.wr_returned_date_sk AS returned_date_sk,
           wr.wr_refunded_customer_sk AS customer_sk,
           wr.wr_item_sk AS item_sk,
           wr.wr_return_quantity AS quantity,
           wr.wr_return_amt AS return_amount,
           'web' AS channel
    FROM web_returns wr
), date_filter AS (
    SELECT d_date_sk
    FROM date_dim
    WHERE d_year = 2002
), cust_sales AS (
    SELECT
        c.c_customer_sk,
        COALESCE(c.c_first_name, '') || ' ' || COALESCE(c.c_last_name, '') || ' (' || COALESCE(c.c_customer_id, 'N/A') || ')' AS customer_label,
        ca.ca_state,
        ca.ca_city,
        SUM(CASE WHEN s.channel = 'catalog' AND df.d_date_sk IS NOT NULL THEN s.net_paid ELSE 0 END) AS catalog_sales,
        SUM(CASE WHEN s.channel = 'store' AND df.d_date_sk IS NOT NULL THEN s.net_paid ELSE 0 END) AS store_sales,
        SUM(CASE WHEN s.channel = 'web' AND df.d_date_sk IS NOT NULL THEN s.net_paid ELSE 0 END) AS web_sales,
        SUM(CASE WHEN df.d_date_sk IS NOT NULL THEN s.net_paid ELSE 0 END) AS total_sales,
        COUNT(DISTINCT CASE WHEN df.d_date_sk IS NOT NULL THEN s.sold_date_sk END) AS sales_days,
        MAX(CASE WHEN df.d_date_sk IS NOT NULL THEN s.sold_date_sk END) AS last_sale_date_sk
    FROM customer c
    LEFT JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    LEFT JOIN sales_union s ON c.c_customer_sk = s.customer_sk
    LEFT JOIN date_filter df ON s.sold_date_sk = df.d_date_sk
    GROUP BY
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        c.c_customer_id,
        ca.ca_state,
        ca.ca_city
), cust_returns AS (
    SELECT
        cr.customer_sk,
        SUM(CASE WHEN cr.channel = 'catalog' THEN cr.return_amount ELSE 0 END) AS catalog_returns,
        SUM(CASE WHEN cr.channel = 'store' THEN cr.return_amount ELSE 0 END) AS store_returns,
        SUM(CASE WHEN cr.channel = 'web' THEN cr.return_amount ELSE 0 END) AS web_returns,
        SUM(cr.return_amount) AS total_returns
    FROM returns_union cr
    JOIN date_filter df ON cr.returned_date_sk = df.d_date_sk
    GROUP BY cr.customer_sk
), cust_demo AS (
    SELECT
        c.c_customer_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        cd.cd_credit_rating,
        CASE WHEN cd.cd_credit_rating = 'AA' THEN 1 ELSE 0 END AS is_premium_credit
    FROM customer c
    LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
)
SELECT
    cs.c_customer_sk,
    cs.customer_label,
    cs.ca_state,
    cs.ca_city,
    cs.total_sales,
    COALESCE(cr.total_returns, 0) AS total_returns,
    cs.total_sales - COALESCE(cr.total_returns, 0) AS net_sales,
    cs.catalog_sales,
    cs.store_sales,
    cs.web_sales,
    COALESCE(cr.catalog_returns, 0) AS catalog_returns,
    COALESCE(cr.store_returns, 0) AS store_returns,
    COALESCE(cr.web_returns, 0) AS web_returns,
    CASE WHEN cs.total_sales = 0 THEN NULL ELSE ROUND((cs.catalog_sales / cs.total_sales) * 100, 2) END AS pct_catalog_sales,
    CASE WHEN cs.total_sales = 0 THEN NULL ELSE ROUND((cs.store_sales / cs.total_sales) * 100, 2) END AS pct_store_sales,
    CASE WHEN cs.total_sales = 0 THEN NULL ELSE ROUND((cs.web_sales / cs.total_sales) * 100, 2) END AS pct_web_sales,
    ROW_NUMBER() OVER (PARTITION BY cs.ca_state ORDER BY (cs.total_sales - COALESCE(cr.total_returns, 0)) DESC) AS state_sales_rank,
    cd.cd_gender,
    cd.cd_marital_status,
    cd.cd_education_status,
    cd.cd_credit_rating,
    cd.is_premium_credit,
    (SELECT AVG(cs2.total_sales - COALESCE(cr2.total_returns, 0))
     FROM cust_sales cs2
     LEFT JOIN cust_returns cr2 ON cs2.c_customer_sk = cr2.customer_sk
     LEFT JOIN cust_demo cd2 ON cs2.c_customer_sk = cd2.c_customer_sk
     WHERE cd2.cd_gender IS NOT DISTINCT FROM cd.cd_gender
       AND cd2.cd_credit_rating IS NOT DISTINCT FROM cd.cd_credit_rating) AS avg_net_sales_same_demo,
    DATE_DIFF('day',
        (SELECT d.d_date FROM date_dim d WHERE d.d_date_sk = cs.last_sale_date_sk),
        DATE '2024-10-01') AS days_since_last_sale
FROM cust_sales cs
LEFT JOIN cust_returns cr ON cs.c_customer_sk = cr.customer_sk
LEFT JOIN cust_demo cd ON cs.c_customer_sk = cd.c_customer_sk
WHERE cs.total_sales > 0
ORDER BY net_sales DESC
LIMIT 100

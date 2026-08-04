WITH store_sales_filtered AS (
    SELECT
        ss.ss_customer_sk AS customer_sk,
        ss.ss_item_sk AS item_sk,
        ss.ss_net_paid AS net_paid
    FROM store_sales ss
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    WHERE regexp_like(i.i_item_desc, 'Deluxe')
      AND i.i_brand LIKE 'A%'
),
catalog_sales_filtered AS (
    SELECT
        cs.cs_bill_customer_sk AS customer_sk,
        cs.cs_item_sk AS item_sk,
        cs.cs_net_paid AS net_paid
    FROM catalog_sales cs
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    WHERE regexp_like(i.i_item_desc, 'Deluxe')
      AND i.i_brand LIKE 'A%'
),
customer_intersection AS (
    SELECT customer_sk FROM store_sales_filtered
    INTERSECT
    SELECT customer_sk FROM catalog_sales_filtered
),
customer_agg AS (
    SELECT
        ssf.customer_sk,
        SUM(ssf.net_paid) AS total_net_paid,
        COUNT(DISTINCT ssf.item_sk) AS distinct_items
    FROM store_sales_filtered ssf
    WHERE ssf.customer_sk IN (SELECT customer_sk FROM customer_intersection)
    GROUP BY ssf.customer_sk
),
reasons_small AS (
    SELECT r_reason_desc
    FROM reason
    WHERE r_reason_sk IN (1, 2, 3)
)
SELECT
    ca.customer_sk,
    CONCAT(c.c_first_name, ' ', c.c_last_name) AS customer_name,
    SUBSTR(c.c_email_address, 1, strpos(c.c_email_address, '@') - 1) AS email_user,
    ca.total_net_paid,
    ca.distinct_items,
    r.r_reason_desc,
    regexp_extract(r.r_reason_desc, '^\\w+', 0) AS reason_keyword
FROM customer_agg ca
JOIN customer c ON ca.customer_sk = c.c_customer_sk
CROSS JOIN reasons_small r
WHERE NOT EXISTS (
        SELECT 1 FROM store_returns sr WHERE sr.sr_customer_sk = ca.customer_sk
    )
  AND NOT EXISTS (
        SELECT 1 FROM catalog_returns cr WHERE cr.cr_refunded_customer_sk = ca.customer_sk
    )
ORDER BY ca.total_net_paid DESC
LIMIT 10

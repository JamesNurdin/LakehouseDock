WITH catalog_agg AS (
    SELECT
        c.c_customer_sk,
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        c.c_email_address,
        cc.cc_name,
        SUM(cr.cr_net_loss) AS total_net_loss,
        COUNT(*) AS return_count,
        CASE WHEN SUM(cr.cr_net_loss) > 1000 THEN 'High' ELSE 'Low' END AS loss_category,
        'Catalog' AS source
    FROM catalog_returns cr
    JOIN catalog_sales cs
        ON cr.cr_order_number = cs.cs_order_number
       AND cr.cr_item_sk = cs.cs_item_sk
    JOIN customer c
        ON cr.cr_returning_customer_sk = c.c_customer_sk
    JOIN call_center cc
        ON cr.cr_call_center_sk = cc.cc_call_center_sk
    WHERE REGEXP_LIKE(c.c_email_address, '^[A-Za-z0-9._%+-]+@example\\.com$')
      AND cc.cc_name LIKE '%Center%'
    GROUP BY
        c.c_customer_sk,
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        c.c_email_address,
        cc.cc_name
),
store_agg AS (
    SELECT
        c.c_customer_sk,
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        c.c_email_address,
        CAST(NULL AS varchar) AS cc_name,
        SUM(sr.sr_net_loss) AS total_net_loss,
        COUNT(*) AS return_count,
        CASE WHEN SUM(sr.sr_net_loss) > 500 THEN 'High' ELSE 'Low' END AS loss_category,
        'Store' AS source
    FROM store_returns sr
    JOIN customer c
        ON sr.sr_customer_sk = c.c_customer_sk
    WHERE REGEXP_LIKE(c.c_email_address, '^[A-Za-z0-9._%+-]+@example\\.com$')
      AND c.c_first_name LIKE 'A%'
    GROUP BY
        c.c_customer_sk,
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        c.c_email_address
),
combined AS (
    SELECT
        c_customer_sk,
        c_customer_id,
        c_first_name,
        c_last_name,
        c_email_address,
        cc_name,
        total_net_loss,
        return_count,
        loss_category,
        source
    FROM catalog_agg
    UNION ALL
    SELECT
        c_customer_sk,
        c_customer_id,
        c_first_name,
        c_last_name,
        c_email_address,
        cc_name,
        total_net_loss,
        return_count,
        loss_category,
        source
    FROM store_agg
),
ranked AS (
    SELECT
        c_customer_id,
        CONCAT(c_first_name, ' ', c_last_name) AS full_name,
        REGEXP_EXTRACT(c_email_address, '@(.+)$', 1) AS email_domain,
        SUBSTRING(c_email_address FROM 1 FOR POSITION('@' IN c_email_address) - 1) AS email_local,
        cc_name,
        total_net_loss,
        loss_category,
        source,
        ROW_NUMBER() OVER (PARTITION BY source ORDER BY total_net_loss DESC) AS rank_in_source,
        ROW_NUMBER() OVER (ORDER BY total_net_loss DESC) AS overall_rank
    FROM combined
)
SELECT DISTINCT
    c_customer_id,
    full_name,
    email_local,
    email_domain,
    cc_name,
    total_net_loss,
    loss_category,
    source,
    rank_in_source,
    overall_rank
FROM ranked
WHERE overall_rank <= 100
ORDER BY total_net_loss DESC
LIMIT 100

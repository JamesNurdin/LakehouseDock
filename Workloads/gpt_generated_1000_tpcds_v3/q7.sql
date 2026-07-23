WITH store_sales_agg AS (
    SELECT
        d.d_date AS event_date,
        s.s_store_name AS source,
        SUM(ss.ss_ext_sales_price) AS total_sales_amount,
        SUM(ss.ss_net_profit) AS total_profit,
        CAST(NULL AS decimal(7,2)) AS total_return_amount,
        CAST(NULL AS decimal(7,2)) AS total_net_loss,
        'store_sales' AS record_type
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    WHERE d.d_year = 2002
    GROUP BY d.d_date, s.s_store_name
),
catalog_returns_agg AS (
    SELECT
        d.d_date AS event_date,
        cp.cp_description AS source,
        CAST(NULL AS decimal(7,2)) AS total_sales_amount,
        CAST(NULL AS decimal(7,2)) AS total_profit,
        SUM(cr.cr_return_amount) AS total_return_amount,
        SUM(cr.cr_net_loss) AS total_net_loss,
        'catalog_returns' AS record_type
    FROM catalog_returns cr
    JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
    JOIN catalog_page cp ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
    WHERE d.d_year = 2002
    GROUP BY d.d_date, cp.cp_description
)
SELECT
    event_date,
    source,
    total_sales_amount,
    total_profit,
    total_return_amount,
    total_net_loss,
    record_type
FROM store_sales_agg
UNION ALL
SELECT
    event_date,
    source,
    total_sales_amount,
    total_profit,
    total_return_amount,
    total_net_loss,
    record_type
FROM catalog_returns_agg
ORDER BY event_date, source

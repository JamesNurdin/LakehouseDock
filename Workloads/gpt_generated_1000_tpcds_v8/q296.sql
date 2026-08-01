WITH sampled_returns AS (
        SELECT *
        FROM store_returns
        TABLESAMPLE BERNOULLI (10)
    ),
    returns_data AS (
        SELECT
            'return' AS source,
            s.s_store_id AS entity_id,
            d.d_year AS year,
            COUNT(DISTINCT sr.sr_ticket_number) AS metric1,
            SUM(sr.sr_return_amt) AS metric2
        FROM sampled_returns sr
        JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
        JOIN store s ON sr.sr_store_sk = s.s_store_sk
        WHERE d.d_year = 2001
          AND s.s_tax_percentage > 0.05
        GROUP BY s.s_store_id, d.d_year
    ),
    catalog_no_returns AS (
        SELECT
            'catalog' AS source,
            cp.cp_catalog_page_id AS entity_id,
            d.d_year AS year,
            CAST(NULL AS BIGINT) AS metric1,
            CAST(NULL AS DOUBLE) AS metric2
        FROM catalog_page cp
        JOIN date_dim d ON cp.cp_start_date_sk = d.d_date_sk
        WHERE d.d_year = 2001
          AND cp.cp_type = 'PROMO'
          AND NOT EXISTS (
              SELECT 1
              FROM store_returns sr
              WHERE sr.sr_returned_date_sk = cp.cp_start_date_sk
          )
    ),
    store_dates AS (
        SELECT
            s.s_store_id,
            s.s_tax_percentage,
            d.d_date_sk,
            d.d_year
        FROM store s
        LEFT JOIN date_dim d ON s.s_closed_date_sk = d.d_date_sk
    ),
    catalog_dates AS (
        SELECT
            cp.cp_catalog_page_id,
            cp.cp_type,
            d.d_date_sk,
            d.d_year
        FROM catalog_page cp
        LEFT JOIN date_dim d ON cp.cp_start_date_sk = d.d_date_sk
    ),
    store_catalog_full AS (
        SELECT
            'store_catalog' AS source,
            COALESCE(sd.s_store_id, cd.cp_catalog_page_id) AS entity_id,
            COALESCE(sd.d_year, cd.d_year) AS year,
            CAST(NULL AS BIGINT) AS metric1,
            CAST(NULL AS DOUBLE) AS metric2
        FROM store_dates sd
        FULL OUTER JOIN catalog_dates cd ON sd.d_date_sk = cd.d_date_sk
        WHERE (sd.s_tax_percentage > 0.05 OR cd.cp_type = 'PROMO')
    )
SELECT *
FROM returns_data
UNION ALL
SELECT *
FROM catalog_no_returns
UNION ALL
SELECT *
FROM store_catalog_full
LIMIT 100

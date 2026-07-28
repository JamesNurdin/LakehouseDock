WITH filtered_items AS (
    SELECT
        i_item_sk,
        i_item_desc,
        i_category,
        REGEXP_EXTRACT(i_item_desc, '(\\w+)', 1) AS first_word
    FROM tpcds.item
    WHERE REGEXP_LIKE(i_item_desc, '(?i)blue')
      AND i_item_desc LIKE '%large%'
),
catalog_agg AS (
    SELECT
        d.d_year AS year,
        sm.sm_carrier AS carrier,
        SUM(cs.cs_net_paid) AS total_sales,
        COUNT(*) AS txn_count,
        CONCAT(CAST(d.d_year AS VARCHAR), '-', sm.sm_carrier) AS year_carrier_key,
        MIN(first_word) AS sample_first_word
    FROM tpcds.catalog_sales cs
    INNER JOIN filtered_items fi ON cs.cs_item_sk = fi.i_item_sk
    INNER JOIN tpcds.date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    INNER JOIN tpcds.ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    GROUP BY d.d_year, sm.sm_carrier
),
web_agg AS (
    SELECT
        d.d_year AS year,
        sm.sm_carrier AS carrier,
        SUM(ws.ws_net_paid) AS total_sales,
        COUNT(*) AS txn_count,
        CONCAT(CAST(d.d_year AS VARCHAR), '-', sm.sm_carrier) AS year_carrier_key,
        MIN(first_word) AS sample_first_word
    FROM tpcds.web_sales ws
    INNER JOIN filtered_items fi ON ws.ws_item_sk = fi.i_item_sk
    INNER JOIN tpcds.date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    INNER JOIN tpcds.ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
    GROUP BY d.d_year, sm.sm_carrier
)
SELECT * FROM catalog_agg
UNION ALL
SELECT * FROM web_agg
ORDER BY year, carrier
LIMIT 100

WITH
store_sales_agg AS (
    SELECT
        s.s_store_id AS store_id,
        d.d_year AS year,
        SUM(ss.ss_net_paid) AS total_net_paid,
        COUNT(*) AS transaction_cnt
    FROM store_sales ss
    JOIN store s
        ON ss.ss_store_sk = s.s_store_sk
    JOIN date_dim d
        ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN time_dim t
        ON ss.ss_sold_time_sk = t.t_time_sk
    JOIN household_demographics hd
        ON ss.ss_hdemo_sk = hd.hd_demo_sk
    WHERE hd.hd_vehicle_count >= 2
      AND d.d_year = 2002
      AND s.s_state = 'CA'
      AND EXISTS (
          SELECT 1
          FROM store_returns sr
          JOIN date_dim dr
              ON sr.sr_returned_date_sk = dr.d_date_sk
          WHERE sr.sr_store_sk = s.s_store_sk
            AND dr.d_year = 2002
      )
    GROUP BY s.s_store_id, d.d_year
),
catalog_sales_agg AS (
    SELECT
        'Catalog' AS store_id,
        d.d_year AS year,
        SUM(cs.cs_net_paid) AS total_net_paid,
        COUNT(*) AS transaction_cnt
    FROM catalog_sales cs
    JOIN date_dim d
        ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN time_dim t
        ON cs.cs_sold_time_sk = t.t_time_sk
    JOIN household_demographics hd
        ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
    WHERE hd.hd_vehicle_count >= 2
      AND d.d_year = 2002
      AND cs.cs_ship_mode_sk IN (
          SELECT DISTINCT cs2.cs_ship_mode_sk
          FROM catalog_sales cs2
          JOIN date_dim d2
              ON cs2.cs_sold_date_sk = d2.d_date_sk
          WHERE d2.d_year = 2002
            AND d2.d_moy = 5
      )
    GROUP BY d.d_year
)
SELECT
    store_id,
    year,
    total_net_paid,
    transaction_cnt,
    'Store' AS sales_type
FROM store_sales_agg
UNION ALL
SELECT
    store_id,
    year,
    total_net_paid,
    transaction_cnt,
    'Catalog' AS sales_type
FROM catalog_sales_agg
ORDER BY total_net_paid DESC
LIMIT 100

/*
Goal: Analyze 2022 sales and returns across stores, web channels, and warehouses, aggregating total sales amount and transaction count by entity and year, ranking entities, calculating average household income upper bound per entity, applying selective filters, anti‑join, window function, rollup grouping, and limiting to top 100 rows.
*/
WITH sales_combined AS (
    SELECT entity_id, entity_type, year, sales_amount
    FROM (
        /* Store sales branch */
        SELECT
            s.s_store_sk AS entity_id,
            'STORE' AS entity_type,
            d.d_year AS year,
            ss.ss_ext_sales_price AS sales_amount
        FROM store_sales ss
        JOIN store s ON ss.ss_store_sk = s.s_store_sk
        JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
        JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
        JOIN customer_demographics cd ON ss.ss_cdemo_sk = cd.cd_demo_sk
        JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
        JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
        WHERE p.p_discount_active = 'Y'
          AND s.s_state = 'TX'
          AND d.d_year = 2022
        UNION ALL
        /* Web sales branch */
        SELECT
            ws.ws_warehouse_sk AS entity_id,
            'WEB' AS entity_type,
            d.d_year AS year,
            ws.ws_ext_sales_price AS sales_amount
        FROM web_sales ws
        JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
        JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
        JOIN warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
        JOIN customer_demographics cd ON ws.ws_bill_cdemo_sk = cd.cd_demo_sk
        JOIN household_demographics hd ON ws.ws_bill_hdemo_sk = hd.hd_demo_sk
        JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
        WHERE p.p_channel_press = 'N'
          AND w.w_city = 'New'
          AND d.d_year = 2022
    ) AS u
),
returns_combined AS (
    SELECT
        w.w_warehouse_sk AS entity_id,
        'WAREHOUSE' AS entity_type,
        d.d_year AS year,
        cr.cr_return_amount AS sales_amount
    FROM catalog_returns cr
    JOIN catalog_page cp ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
    JOIN warehouse w ON cr.cr_warehouse_sk = w.w_warehouse_sk
    JOIN customer_demographics cd ON cr.cr_refunded_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd ON cr.cr_refunded_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    WHERE cp.cp_catalog_number IN (10, 12, 15)
      AND w.w_city = 'New'
      AND d.d_year = 2022
),
union_all_data AS (
    SELECT entity_id, entity_type, year, sales_amount FROM sales_combined
    UNION
    SELECT entity_id, entity_type, year, sales_amount FROM returns_combined
),
aggregated AS (
    SELECT
        entity_type,
        entity_id,
        year,
        SUM(sales_amount) AS total_sales_amount,
        COUNT(*) AS transaction_cnt
    FROM union_all_data
    WHERE sales_amount > 0
    GROUP BY ROLLUP (entity_type, entity_id, year)
    HAVING entity_type IS NOT NULL AND entity_id IS NOT NULL AND year IS NOT NULL
)
SELECT
    a.entity_type,
    a.entity_id,
    a.year,
    a.total_sales_amount,
    a.transaction_cnt,
    ROW_NUMBER() OVER (PARTITION BY a.entity_type ORDER BY a.total_sales_amount DESC) AS rn,
    CASE
        WHEN a.entity_type = 'STORE' THEN (
            SELECT AVG(ib2.ib_upper_bound)
            FROM store_sales ss2
            JOIN household_demographics hd2 ON ss2.ss_hdemo_sk = hd2.hd_demo_sk
            JOIN income_band ib2 ON hd2.hd_income_band_sk = ib2.ib_income_band_sk
            WHERE ss2.ss_store_sk = a.entity_id
        )
        WHEN a.entity_type = 'WAREHOUSE' THEN (
            SELECT AVG(ib2.ib_upper_bound)
            FROM catalog_returns cr2
            JOIN household_demographics hd2 ON cr2.cr_refunded_hdemo_sk = hd2.hd_demo_sk
            JOIN income_band ib2 ON hd2.hd_income_band_sk = ib2.ib_income_band_sk
            WHERE cr2.cr_warehouse_sk = a.entity_id
        )
        WHEN a.entity_type = 'WEB' THEN (
            SELECT AVG(ib2.ib_upper_bound)
            FROM web_sales ws2
            JOIN household_demographics hd2 ON ws2.ws_bill_hdemo_sk = hd2.hd_demo_sk
            JOIN income_band ib2 ON hd2.hd_income_band_sk = ib2.ib_income_band_sk
            WHERE ws2.ws_warehouse_sk = a.entity_id
        )
    END AS avg_income_upper_bound
FROM aggregated a
WHERE NOT EXISTS (
    SELECT 1
    FROM catalog_returns cr3
    WHERE cr3.cr_warehouse_sk = a.entity_id
      AND cr3.cr_return_amount > 5000
      AND a.entity_type = 'WAREHOUSE'
)
ORDER BY a.total_sales_amount DESC
LIMIT 100

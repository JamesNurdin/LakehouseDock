/*
Goal: Calculate per‑state yearly return statistics for the year 2001 for items whose manufacturer name ends with "able" and whose product name contains "Table", exclude items from the discontinued brand, and show a cumulative sum of the average return amount across states.
*/
WITH filtered_returns AS (
    SELECT
        cr.cr_return_amount,
        d.d_year,
        d.d_date,
        w.w_state,
        i.i_brand,
        i.i_category,
        i.i_manufact,
        i.i_product_name,
        w.w_warehouse_name
    FROM catalog_returns cr
    JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
    JOIN item i ON cr.cr_item_sk = i.i_item_sk
    JOIN warehouse w ON cr.cr_warehouse_sk = w.w_warehouse_sk
    WHERE d.d_date BETWEEN DATE '2001-01-01' AND DATE '2001-12-31'
      AND regexp_like(i.i_manufact, '.*able$')
      AND i.i_product_name LIKE '%Table%'
      AND NOT EXISTS (
          SELECT 1
          FROM item i2
          WHERE i2.i_item_sk = cr.cr_item_sk
            AND i2.i_brand = 'Discontinued'
      )
),
aggregated AS (
    SELECT
        w_state,
        d_year,
        CONCAT(i_brand, '-', i_category) AS brand_category,
        SUBSTRING(w_warehouse_name, 1, 5) AS wh_prefix,
        COUNT(*) AS returns_cnt,
        AVG(cr_return_amount) AS avg_return_amount,
        MAX(d_date) AS max_date
    FROM filtered_returns
    GROUP BY w_state, d_year, i_brand, i_category, w_warehouse_name
)
SELECT
    w_state,
    d_year,
    brand_category,
    wh_prefix,
    returns_cnt,
    avg_return_amount,
    SUM(avg_return_amount) OVER (
        PARTITION BY w_state
        ORDER BY max_date
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    ) AS cum_avg_return_amount
FROM aggregated
ORDER BY cum_avg_return_amount DESC
LIMIT 100

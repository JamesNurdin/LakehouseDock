WITH sales_data AS (
    SELECT
        ss.ss_sold_date_sk,
        ss.ss_item_sk,
        ss.ss_quantity,
        ss.ss_ext_sales_price,
        d.d_date,
        d.d_year,
        d.d_month_seq,
        CASE WHEN ss.ss_quantity > 10 THEN 'Bulk' ELSE 'Regular' END AS quantity_type
    FROM store_sales ss
    FULL OUTER JOIN date_dim d
        ON ss.ss_sold_date_sk = d.d_date_sk
        AND d.d_year BETWEEN 1999 AND 2001
)
SELECT
    sd.d_date,
    sd.d_year,
    sd.quantity_type,
    cs.cs_order_number,
    cs.cs_ext_tax,
    ship.sm_type,
    wh.w_city,
    wh.w_state,
    CONCAT(wh.w_city, ', ', wh.w_state) AS location,
    CASE WHEN cs.cs_ext_tax > 100 THEN 'High' ELSE 'Low' END AS tax_category,
    (SELECT MAX(d_year) FROM date_dim) AS max_year_ref,
    (SELECT COUNT(*) FROM catalog_sales cs2 WHERE cs2.cs_ship_mode_sk = ship.sm_ship_mode_sk) AS mode_ship_count
FROM sales_data sd
LEFT JOIN catalog_sales cs
    ON cs.cs_sold_date_sk = sd.ss_sold_date_sk
LEFT JOIN ship_mode ship
    ON cs.cs_ship_mode_sk = ship.sm_ship_mode_sk
LEFT JOIN warehouse wh
    ON cs.cs_warehouse_sk = wh.w_warehouse_sk
WHERE NOT EXISTS (
        SELECT 1
        FROM catalog_sales cs3
        WHERE cs3.cs_sold_date_sk = sd.ss_sold_date_sk
          AND cs3.cs_ext_tax = cs.cs_ext_tax
    )
  AND regexp_like(wh.w_city, '^A')               -- city names starting with 'A'
  AND wh.w_zip LIKE '45%'                        -- ZIP codes beginning with 45
  AND cs.cs_ext_tax = (SELECT MIN(cs4.cs_ext_tax) FROM catalog_sales cs4)  -- scalar comparison
  AND cs.cs_ship_mode_sk IN (
        SELECT sm_ship_mode_sk
        FROM ship_mode
        WHERE sm_type LIKE '%AIR%'
    )
ORDER BY sd.d_date DESC
OFFSET 0 LIMIT 100

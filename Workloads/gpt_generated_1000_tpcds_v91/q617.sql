WITH filtered_items AS (
    SELECT
        ss.ss_store_sk,
        ss.ss_item_sk,
        i.i_item_id,
        i.i_brand,
        i.i_category,
        SUM(ss.ss_ext_sales_price) AS total_sales,
        SUM(ss.ss_net_profit) AS total_profit,
        COUNT(*) AS sales_cnt
    FROM store_sales ss
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
    JOIN time_dim t ON ss.ss_sold_time_sk = t.t_time_sk
    WHERE regexp_like(i.i_item_desc, '\\d{2,}')               -- description contains at least two digits
      AND i.i_brand LIKE 'A%'                                 -- brand starts with 'A'
      AND hd.hd_buy_potential = '1001-5000'                  -- modest buying potential
    GROUP BY
        ss.ss_store_sk,
        ss.ss_item_sk,
        i.i_item_id,
        i.i_brand,
        i.i_category
)
SELECT
    f.ss_store_sk,
    f.i_item_id,
    f.i_brand,
    f.i_category,
    concat(f.i_brand, '-', f.i_category) AS brand_cat,
    f.total_sales,
    f.total_profit,
    f.sales_cnt,
    l.numeric_part,
    substring(f.i_brand, 1, 3) AS brand_prefix,
    RANK() OVER (PARTITION BY f.ss_store_sk ORDER BY f.total_sales DESC) AS sales_rank,
    (
        SELECT AVG(fi.total_sales)
        FROM filtered_items fi
        WHERE fi.i_brand = f.i_brand
    ) AS avg_brand_sales,
    EXISTS (
        SELECT 1
        FROM catalog_sales cs
        JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
        JOIN item i ON cs.cs_item_sk = i.i_item_sk
        WHERE i.i_item_sk = f.ss_item_sk
          AND regexp_like(sm.sm_contract, 'A')
    ) AS has_ship_mode_with_A_contract
FROM filtered_items f
CROSS JOIN LATERAL (
    SELECT regexp_extract(f.i_item_id, '(\\d+)', 1) AS numeric_part
) AS l
WHERE f.total_sales > (SELECT AVG(total_sales) FROM filtered_items) + 1000
ORDER BY f.total_sales DESC
LIMIT 100

WITH distinct_warehouses AS (
    SELECT DISTINCT
        w.w_warehouse_sk,
        w.w_warehouse_id,
        w.w_county,
        w.w_zip,
        w.w_state,
        w.w_country,
        w.w_gmt_offset
    FROM warehouse w
    WHERE w.w_state = 'CA'
      AND w.w_country = 'United States'
),

inv_warehouse AS (
    SELECT
        inv.inv_item_sk,
        inv.inv_warehouse_sk,
        SUM(inv.inv_quantity_on_hand) AS total_quantity_on_hand,
        dw.w_warehouse_id,
        dw.w_county,
        dw.w_zip
    FROM inventory inv
    FULL OUTER JOIN distinct_warehouses dw
        ON inv.inv_warehouse_sk = dw.w_warehouse_sk
    GROUP BY inv.inv_item_sk, inv.inv_warehouse_sk, dw.w_warehouse_id, dw.w_county, dw.w_zip
),

returns_agg AS (
    SELECT
        wr.wr_item_sk,
        SUM(wr.wr_return_amt) AS total_return_amount,
        COUNT(DISTINCT wr.wr_order_number) AS distinct_return_orders,
        MAX(wp.wp_type) AS max_page_type
    FROM web_returns wr
    JOIN web_page wp
        ON wr.wr_web_page_sk = wp.wp_web_page_sk
    GROUP BY wr.wr_item_sk
),

final AS (
    SELECT
        dw.w_warehouse_id,
        i.i_item_id,
        i.i_brand,
        sm.sm_code,
        COUNT(DISTINCT cs.cs_order_number) AS distinct_orders,
        SUM(cs.cs_ext_sales_price) AS total_sales,
        SUM(cs.cs_ext_discount_amt) AS total_discount,
        AVG(cs.cs_ext_discount_amt / NULLIF(cs.cs_ext_sales_price, 0)) AS avg_discount_rate,
        COALESCE(iw.total_quantity_on_hand, 0) AS inventory_on_hand,
        COALESCE(ra.total_return_amount, 0) AS total_return_amount,
        SUM(cs.cs_ext_sales_price) - COALESCE(ra.total_return_amount, 0) AS net_sales,
        (
            SELECT MAX(i2.i_current_price)
            FROM item i2
            WHERE i2.i_brand = i.i_brand
        ) AS max_price_for_brand
    FROM catalog_sales cs
    JOIN ship_mode sm
        ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN item i
        ON cs.cs_item_sk = i.i_item_sk
    JOIN distinct_warehouses dw
        ON cs.cs_warehouse_sk = dw.w_warehouse_sk
    LEFT JOIN inv_warehouse iw
        ON i.i_item_sk = iw.inv_item_sk
        AND dw.w_warehouse_sk = iw.inv_warehouse_sk
    LEFT JOIN returns_agg ra
        ON i.i_item_sk = ra.wr_item_sk
    WHERE sm.sm_contract = 'O9V6oF8RJnLMmZYd1'
      AND sm.sm_code = 'AIR'
      AND cs.cs_sold_date_sk BETWEEN 2451150 AND 2451210
      AND i.i_brand = 'Brand#12'
      AND dw.w_county = 'Marshall County'
      AND dw.w_zip = '74136'
      AND EXISTS (
          SELECT 1
          FROM catalog_page cp
          WHERE cp.cp_catalog_page_sk = cs.cs_catalog_page_sk
            AND cp.cp_type = 'Promotion'
            AND cp.cp_department = 'Electronics'
      )
      AND NOT EXISTS (
          SELECT 1
          FROM web_returns wr2
          WHERE wr2.wr_item_sk = i.i_item_sk
            AND wr2.wr_return_quantity > 10
      )
    GROUP BY
        dw.w_warehouse_id,
        i.i_item_id,
        i.i_brand,
        sm.sm_code,
        iw.total_quantity_on_hand,
        ra.total_return_amount
    HAVING SUM(cs.cs_ext_sales_price) > 10000
       AND COUNT(DISTINCT cs.cs_order_number) >= 10
)
SELECT
    w_warehouse_id,
    i_item_id,
    i_brand,
    sm_code,
    distinct_orders,
    total_sales,
    total_discount,
    avg_discount_rate,
    inventory_on_hand,
    total_return_amount,
    net_sales,
    max_price_for_brand
FROM final
ORDER BY total_sales DESC
LIMIT 100

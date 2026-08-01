WITH sampled_returns AS (
    SELECT *
    FROM catalog_returns
    TABLESAMPLE BERNOULLI (10)
),
union_items AS (
    SELECT i_item_sk,
           i_product_name,
           i_brand,
           i_category
    FROM item
    WHERE i_product_name LIKE '%Premium%'
    UNION DISTINCT
    SELECT i_item_sk,
           i_product_name,
           i_brand,
           i_category
    FROM item
    WHERE regexp_like(i_product_name, '^.*[0-9]{3}.*$')
),
intersect_brands AS (
    SELECT i_item_sk FROM item WHERE i_brand LIKE 'Brand%'
    INTERSECT
    SELECT i_item_sk FROM item WHERE regexp_like(i_color, '^Red|Blue$')
),
filtered_returns AS (
    SELECT sr.cr_returned_date_sk,
           sr.cr_returned_time_sk,
           sr.cr_item_sk,
           sr.cr_refunded_customer_sk,
           sr.cr_refunded_cdemo_sk,
           sr.cr_refunded_hdemo_sk,
           sr.cr_refunded_addr_sk,
           sr.cr_returning_customer_sk,
           sr.cr_returning_cdemo_sk,
           sr.cr_returning_hdemo_sk,
           sr.cr_returning_addr_sk,
           sr.cr_call_center_sk,
           sr.cr_catalog_page_sk,
           sr.cr_ship_mode_sk,
           sr.cr_warehouse_sk,
           sr.cr_reason_sk,
           sr.cr_order_number,
           sr.cr_return_quantity,
           sr.cr_return_amt_inc_tax,
           sr.cr_return_tax,
           sr.cr_return_ship_cost,
           sr.cr_fee,
           sr.cr_refunded_cash,
           sr.cr_reversed_charge,
           sr.cr_store_credit,
           sr.cr_net_loss,
           i.i_item_sk,
           i.i_product_name,
           i.i_brand,
           i.i_category,
           hd.hd_demo_sk,
           hd.hd_buy_potential,
           hd.hd_vehicle_count
    FROM sampled_returns sr
    JOIN union_items ui ON sr.cr_item_sk = ui.i_item_sk
    JOIN item i ON sr.cr_item_sk = i.i_item_sk
    JOIN household_demographics hd ON sr.cr_refunded_hdemo_sk = hd.hd_demo_sk
    WHERE NOT EXISTS (
        SELECT 1
        FROM item i2
        WHERE i2.i_category = i.i_category
          AND i2.i_wholesale_cost > 5
    )
      AND i.i_item_sk IN (SELECT i_item_sk FROM intersect_brands)
      AND regexp_extract(i.i_product_name, '(\\d{3})', 1) IS NOT NULL
)
SELECT
    fr.i_item_sk,
    fr.i_product_name,
    fr.i_brand,
    fr.hd_buy_potential,
    CONCAT(fr.i_brand, '-', fr.hd_buy_potential) AS brand_buy_potential,
    SUM(fr.cr_return_amt_inc_tax) AS total_return_amount,
    COUNT(DISTINCT fr.cr_order_number) AS distinct_orders,
    (
        SELECT SUM(cr_return_amt_inc_tax)
        FROM catalog_returns cr3
        WHERE cr3.cr_refunded_hdemo_sk = fr.hd_demo_sk
    ) AS total_return_by_buy_potential,
    SUBSTRING(fr.i_product_name, 1, 10) AS product_name_prefix
FROM filtered_returns fr
GROUP BY
    fr.i_item_sk,
    fr.i_product_name,
    fr.i_brand,
    fr.hd_buy_potential,
    fr.hd_demo_sk
ORDER BY total_return_amount DESC
LIMIT 100

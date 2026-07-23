WITH item_sales AS (
    SELECT
        i.i_item_sk,
        i.i_item_id,
        i.i_product_name,
        i.i_brand,
        i.i_category,
        i.i_manufact_id,
        i.i_class,
        i.i_current_price,
        SUM(ss.ss_ext_sales_price) AS total_sales,
        SUM(ss.ss_net_profit) AS total_profit,
        SUM(ss.ss_quantity) AS total_quantity_sold,
        SUM(inv.inv_quantity_on_hand) AS total_inventory_qty,
        AVG(ss.ss_coupon_amt) AS avg_coupon_amt
    FROM
        item i
        JOIN store_sales ss ON ss.ss_item_sk = i.i_item_sk
        JOIN inventory inv ON inv.inv_item_sk = i.i_item_sk
    WHERE
        i.i_rec_start_date >= DATE '1999-01-01'
        AND i.i_rec_start_date <= DATE '2000-12-31'
        AND i.i_manufact_id IN (26, 350, 117)
        AND i.i_class IN ('shirts', 'accessories')
        AND inv.inv_warehouse_sk IN (4, 10, 17)
        AND inv.inv_quantity_on_hand > 0
        AND ss.ss_ext_wholesale_cost > 500.00
        AND ss.ss_sales_price BETWEEN 10 AND 100
    GROUP BY
        i.i_item_sk,
        i.i_item_id,
        i.i_product_name,
        i.i_brand,
        i.i_category,
        i.i_manufact_id,
        i.i_class,
        i.i_current_price
)
SELECT
    i_brand AS brand,
    i_category AS category,
    SUM(total_sales) AS brand_category_sales,
    SUM(total_profit) AS brand_category_profit,
    AVG(total_sales) AS avg_item_sales,
    COUNT(*) AS num_items
FROM
    item_sales
GROUP BY
    i_brand,
    i_category
HAVING
    SUM(total_sales) > 10000
ORDER BY
    brand_category_sales DESC
LIMIT 20

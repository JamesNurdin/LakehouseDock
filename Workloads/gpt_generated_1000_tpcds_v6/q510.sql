WITH joined_data AS (
    SELECT
        cr.cr_order_number,
        cr.cr_return_amount,
        cr.cr_return_quantity,
        cr.cr_returned_date_sk,
        i.i_item_sk,
        i.i_brand AS i_brand,
        i.i_current_price,
        cd.cd_gender,
        cd.cd_dep_employed_count,
        inv.inv_quantity_on_hand,
        ws.ws_sales_price,
        ws.ws_list_price,
        ws.ws_ext_ship_cost,
        wp.wp_type,
        wp.wp_image_count,
        CASE 
            WHEN cr.cr_return_amount < 20 THEN 'Low'
            WHEN cr.cr_return_amount < 100 THEN 'Medium'
            ELSE 'High'
        END AS return_amount_bucket
    FROM catalog_returns cr
    JOIN item i ON cr.cr_item_sk = i.i_item_sk
    JOIN customer_demographics cd ON cr.cr_refunded_cdemo_sk = cd.cd_demo_sk
    JOIN inventory inv ON i.i_item_sk = inv.inv_item_sk
    JOIN web_sales ws ON i.i_item_sk = ws.ws_item_sk
    JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
    WHERE i.i_current_price > 20
      AND inv.inv_quantity_on_hand BETWEEN 100 AND 1000
      AND cd.cd_gender = 'M'
      AND wp.wp_image_count >= 3
      AND ws.ws_ext_ship_cost < 1000
      AND cr.cr_return_quantity > 1
      AND cr.cr_return_amount > 10
      AND cd.cd_dep_employed_count >= 2
)
SELECT
    i_brand,
    cd_gender,
    wp_type,
    return_amount_bucket,
    COUNT(DISTINCT cr_order_number) AS distinct_returns,
    SUM(cr_return_amount) AS total_return_amount,
    AVG(ws_sales_price) AS avg_sales_price,
    MIN(i_current_price) AS min_item_price,
    MAX(inv_quantity_on_hand) AS max_inventory_qty
FROM joined_data
GROUP BY
    i_brand,
    cd_gender,
    wp_type,
    return_amount_bucket
ORDER BY total_return_amount DESC
LIMIT 100

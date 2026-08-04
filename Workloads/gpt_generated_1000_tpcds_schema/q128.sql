WITH
    filtered_sales AS (
        SELECT
            ws_item_sk,
            SUM(ws_net_paid_inc_ship) AS total_net_paid,
            SUM(ws_quantity) AS total_qty,
            AVG(ws_ext_discount_amt) AS avg_discount
        FROM tpcds.web_sales
        WHERE ws_ext_discount_amt > 500
          AND ws_quantity > 1
          AND ws_net_paid_inc_ship BETWEEN 2000 AND 5000
          AND ws_ship_customer_sk IN (8112527, 9866274, 8186677)
          AND ws_sold_date_sk BETWEEN 2450000 AND 2455000
          AND ws_list_price > 0
        GROUP BY ws_item_sk
    ),
    filtered_items AS (
        SELECT
            i_item_sk,
            i_color,
            i_category,
            i_brand,
            i_rec_start_date,
            i_brand_id,
            i_size,
            i_manager_id
        FROM tpcds.item
        WHERE i_color IN ('purple', 'pink', 'sienna')
          AND i_category = 'Sports'
          AND i_rec_start_date >= DATE '1999-01-01'
          AND i_brand_id BETWEEN 10 AND 20
          AND i_size IS NOT NULL
          AND i_manager_id IS NOT NULL
    ),
    intersect_keys AS (
        SELECT i_item_sk FROM tpcds.item WHERE i_brand_id BETWEEN 15 AND 18
        INTERSECT
        SELECT ws_item_sk FROM tpcds.web_sales WHERE ws_ext_discount_amt > 1000
    )
SELECT
    fi.i_item_sk,
    fi.i_color,
    fi.i_category,
    fi.i_brand,
    fi.i_rec_start_date,
    COALESCE(fs.total_net_paid, 0) AS total_net_paid,
    COALESCE(fs.total_qty, 0) AS total_qty,
    COALESCE(fs.avg_discount, 0) AS avg_discount,
    RANK() OVER (PARTITION BY fi.i_category ORDER BY COALESCE(fs.total_net_paid, 0) DESC) AS category_rank,
    ROW_NUMBER() OVER (ORDER BY COALESCE(fs.total_net_paid, 0) DESC) AS overall_row_num,
    CASE
        WHEN COALESCE(fs.total_qty, 0) > 100 THEN 'HIGH_VOLUME'
        ELSE 'NORMAL_VOLUME'
    END AS volume_level
FROM filtered_items fi
RIGHT OUTER JOIN filtered_sales fs
    ON fs.ws_item_sk = fi.i_item_sk
INNER JOIN intersect_keys ik
    ON ik.i_item_sk = fi.i_item_sk
WHERE fi.i_manager_id > 0
ORDER BY category_rank, total_net_paid DESC
LIMIT 100

WITH inv_union AS (
    SELECT inv_date_sk, inv_item_sk, inv_warehouse_sk, inv_quantity_on_hand
    FROM inventory
    WHERE inv_quantity_on_hand > 0
    UNION ALL
    SELECT inv_date_sk, inv_item_sk, inv_warehouse_sk, inv_quantity_on_hand
    FROM inventory
    WHERE inv_quantity_on_hand < 0
),
filtered_inventory AS (
    SELECT *
    FROM inv_union
    WHERE inv_quantity_on_hand <> 0
),
joined_data AS (
    SELECT
        w.w_warehouse_name AS w_warehouse_name,
        it.i_brand AS i_brand,
        d.d_year AS d_year,
        fi.inv_quantity_on_hand,
        it.i_current_price
    FROM filtered_inventory fi
    JOIN date_dim d ON fi.inv_date_sk = d.d_date_sk
    JOIN item it ON fi.inv_item_sk = it.i_item_sk
    JOIN warehouse w ON fi.inv_warehouse_sk = w.w_warehouse_sk
    JOIN customer c ON c.c_first_shipto_date_sk = d.d_date_sk
    WHERE d.d_fy_week_seq = 12
      AND w.w_street_type = 'Road'
      AND it.i_rec_start_date >= DATE '2000-01-01'
      AND it.i_rec_end_date <= DATE '2005-12-31'
      AND c.c_preferred_cust_flag = 'Y'
),
agg AS (
    SELECT
        w_warehouse_name,
        i_brand,
        d_year,
        SUM(inv_quantity_on_hand) AS total_quantity,
        AVG(i_current_price) AS avg_price,
        COUNT(DISTINCT i_current_price) AS distinct_price_count,
        MIN(i_current_price) AS min_price,
        MAX(i_current_price) AS max_price
    FROM joined_data
    GROUP BY ROLLUP (w_warehouse_name, i_brand, d_year)
)
SELECT
    w_warehouse_name,
    i_brand,
    d_year,
    total_quantity,
    avg_price,
    distinct_price_count,
    min_price,
    max_price,
    (SELECT AVG(i_current_price) FROM item) AS overall_avg_price,
    SUM(total_quantity) OVER (PARTITION BY w_warehouse_name) AS warehouse_quantity_total,
    RANK() OVER (ORDER BY total_quantity DESC) AS quantity_rank
FROM agg
ORDER BY w_warehouse_name, i_brand, d_year
LIMIT 100

WITH joined_data AS (
    SELECT
        d.d_date AS sale_date,
        d.d_year,
        w.w_warehouse_name,
        w.w_warehouse_sk AS warehouse_sk,
        w.w_zip,
        ib.ib_upper_bound AS income_upper_bound,
        cd.cd_gender,
        cd.cd_marital_status,
        hd.hd_vehicle_count,
        cs.cs_item_sk,
        cs.cs_quantity AS cs_quantity,
        cs.cs_net_paid AS cs_net_paid,
        cs.cs_net_profit AS cs_net_profit,
        cs.cs_sales_price AS cs_sales_price,
        ss.ss_item_sk AS ss_item_sk,
        ss.ss_quantity AS ss_quantity,
        ss.ss_net_paid AS ss_net_paid,
        ss.ss_net_profit AS ss_net_profit,
        ss.ss_sales_price AS ss_sales_price,
        inv.inv_quantity_on_hand AS inventory_qty
    FROM catalog_sales cs
    INNER JOIN date_dim d
        ON cs.cs_sold_date_sk = d.d_date_sk
    INNER JOIN time_dim t
        ON cs.cs_sold_time_sk = t.t_time_sk
    INNER JOIN warehouse w
        ON cs.cs_warehouse_sk = w.w_warehouse_sk
    INNER JOIN household_demographics hd
        ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
    INNER JOIN income_band ib
        ON hd.hd_income_band_sk = ib.ib_income_band_sk
    INNER JOIN customer_demographics cd
        ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
    INNER JOIN inventory inv
        ON inv.inv_date_sk = d.d_date_sk
        AND inv.inv_warehouse_sk = w.w_warehouse_sk
    INNER JOIN store_sales ss
        ON ss.ss_sold_date_sk = d.d_date_sk
        AND ss.ss_sold_time_sk = t.t_time_sk
        AND ss.ss_cdemo_sk = cd.cd_demo_sk
        AND ss.ss_hdemo_sk = hd.hd_demo_sk
    WHERE
        d.d_year = 2001
        AND w.w_zip = '44593'
        AND ib.ib_upper_bound = 50000
        AND cd.cd_gender = 'M'
        AND hd.hd_vehicle_count >= 2
        AND cs.cs_quantity > 5
        AND ss.ss_quantity > 2
        AND EXISTS (
            SELECT 1
            FROM catalog_sales cs2
            WHERE cs2.cs_item_sk = ss.ss_item_sk
              AND cs2.cs_sold_date_sk = ss.ss_sold_date_sk
              AND cs2.cs_quantity > 10
        )
)
SELECT
    sale_date,
    d_year,
    w_warehouse_name,
    income_upper_bound,
    cd_gender,
    warehouse_sk,
    COUNT(DISTINCT cs_item_sk) AS distinct_catalog_items,
    COUNT(DISTINCT ss_item_sk) AS distinct_store_items,
    SUM(cs_net_paid) AS total_catalog_net_paid,
    SUM(ss_net_paid) AS total_store_net_paid,
    AVG(cs_sales_price) AS avg_catalog_sales_price,
    AVG(ss_sales_price) AS avg_store_sales_price,
    MIN(inventory_qty) AS min_inventory_qty,
    MAX(inventory_qty) AS max_inventory_qty,
    (
        SELECT AVG(inv2.inv_quantity_on_hand)
        FROM inventory inv2
        WHERE inv2.inv_warehouse_sk = warehouse_sk
    ) AS avg_inventory_qty_warehouse
FROM joined_data
GROUP BY
    sale_date,
    d_year,
    w_warehouse_name,
    income_upper_bound,
    cd_gender,
    warehouse_sk
ORDER BY total_catalog_net_paid DESC
LIMIT 100

-- Goal: Analyze sales performance across store and catalog channels for the year 2001, combining sales, returns, inventory, demographics and web site data, applying multiple filters, computing an average catalog net paid per item, and ranking items by total net paid.
WITH store_data AS (
    SELECT
        d.d_year AS year,
        d.d_weekend AS weekend,
        i.i_item_sk AS item_sk,
        i.i_item_id AS item_id,
        i.i_product_name AS product_name,
        i.i_category_id AS category_id,
        i.i_class_id AS class_id,
        ss.ss_quantity AS quantity,
        ss.ss_sales_price AS sales_price,
        ss.ss_net_paid AS net_paid,
        inv.inv_quantity_on_hand AS inventory_on_hand,
        CASE WHEN sr.sr_return_quantity IS NOT NULL THEN 1 ELSE 0 END AS has_return,
        s.s_store_name AS store_name,
        s.s_state AS store_state,
        CAST(NULL AS integer) AS catalog_page_number,
        CAST(NULL AS varchar) AS department,
        CAST(NULL AS varchar) AS ship_mode_id,
        CAST(NULL AS varchar) AS carrier,
        ws.web_name AS web_name,
        'store' AS source
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN time_dim t ON ss.ss_sold_time_sk = t.t_time_sk
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    LEFT JOIN store_returns sr
        ON ss.ss_ticket_number = sr.sr_ticket_number
        AND ss.ss_item_sk = sr.sr_item_sk
    JOIN inventory inv
        ON inv.inv_item_sk = i.i_item_sk
        AND inv.inv_date_sk = d.d_date_sk
    JOIN web_site ws
        ON ws.web_open_date_sk = d.d_date_sk
),
catalog_data AS (
    SELECT
        d.d_year AS year,
        d.d_weekend AS weekend,
        i.i_item_sk AS item_sk,
        i.i_item_id AS item_id,
        i.i_product_name AS product_name,
        i.i_category_id AS category_id,
        i.i_class_id AS class_id,
        cs.cs_quantity AS quantity,
        cs.cs_sales_price AS sales_price,
        cs.cs_net_paid AS net_paid,
        inv.inv_quantity_on_hand AS inventory_on_hand,
        CAST(NULL AS integer) AS has_return,
        CAST(NULL AS varchar) AS store_name,
        CAST(NULL AS varchar) AS store_state,
        cp.cp_catalog_page_number AS catalog_page_number,
        cp.cp_department AS department,
        sm.sm_ship_mode_id AS ship_mode_id,
        sm.sm_carrier AS carrier,
        ws.web_name AS web_name,
        'catalog' AS source
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN time_dim t ON cs.cs_sold_time_sk = t.t_time_sk
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    JOIN household_demographics hd ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
    JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN inventory inv
        ON inv.inv_item_sk = i.i_item_sk
        AND inv.inv_date_sk = d.d_date_sk
    JOIN web_site ws
        ON ws.web_open_date_sk = d.d_date_sk
),
combined AS (
    SELECT * FROM store_data
    UNION ALL
    SELECT * FROM catalog_data
),
aggregated AS (
    SELECT
        year,
        item_sk,
        item_id,
        product_name,
        category_id,
        class_id,
        SUM(quantity) AS total_quantity,
        SUM(sales_price * quantity) AS total_sales,
        SUM(net_paid) AS total_net_paid,
        SUM(inventory_on_hand) AS total_inventory_on_hand,
        MAX(has_return) AS any_return_flag,
        MAX(store_name) AS store_name,
        MAX(store_state) AS store_state,
        MAX(catalog_page_number) AS catalog_page_number,
        MAX(department) AS department,
        MAX(ship_mode_id) AS ship_mode_id,
        MAX(carrier) AS carrier,
        MAX(web_name) AS web_name,
        COUNT(DISTINCT source) AS sources_count,
        (SELECT AVG(cs2.cs_net_paid)
         FROM catalog_sales cs2
         WHERE cs2.cs_item_sk = item_sk) AS avg_catalog_net_paid
    FROM combined
    WHERE year = 2001
      AND weekend = 'N'
      AND category_id IN (1, 5)
      AND class_id = 6
      AND (store_state = 'CA' OR store_state IS NULL)
      AND (carrier = 'UPS' OR carrier IS NULL)
      AND EXISTS (SELECT 1
                  FROM store_returns sr_check
                  WHERE sr_check.sr_item_sk = item_sk
                    AND sr_check.sr_return_quantity > 0)
    GROUP BY
        year,
        item_sk,
        item_id,
        product_name,
        category_id,
        class_id
)
SELECT
    year,
    item_id,
    product_name,
    category_id,
    class_id,
    total_quantity,
    total_sales,
    total_net_paid,
    total_inventory_on_hand,
    any_return_flag,
    store_name,
    store_state,
    catalog_page_number,
    department,
    ship_mode_id,
    carrier,
    web_name,
    sources_count,
    avg_catalog_net_paid,
    RANK() OVER (PARTITION BY year ORDER BY total_net_paid DESC) AS net_paid_rank,
    SUM(total_net_paid) OVER (PARTITION BY year ORDER BY total_net_paid DESC
                              ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS cumulative_net_paid
FROM aggregated
ORDER BY net_paid_rank
LIMIT 100

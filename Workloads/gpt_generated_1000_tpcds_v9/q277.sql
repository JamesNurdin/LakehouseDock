WITH joined_data AS (
    SELECT
        s.s_state AS s_state,
        d_sold.d_year AS d_year,
        cs.cs_ext_sales_price AS cs_sales,
        ss.ss_ext_sales_price AS ss_sales,
        cs.cs_net_profit AS cs_profit,
        i.inv_quantity_on_hand AS inv_qty,
        sm.sm_type AS sm_type,
        wp.wp_max_ad_count AS wp_max_ad_count,
        cp.cp_catalog_page_id AS cp_catalog_page_id
    FROM date_dim d_sold
    INNER JOIN store_sales ss
        ON ss.ss_sold_date_sk = d_sold.d_date_sk
    INNER JOIN store s
        ON ss.ss_store_sk = s.s_store_sk
    INNER JOIN date_dim d_store_closed
        ON s.s_closed_date_sk = d_store_closed.d_date_sk
    INNER JOIN customer_address ca_ss
        ON ss.ss_addr_sk = ca_ss.ca_address_sk
    INNER JOIN customer_demographics cd_ss
        ON ss.ss_cdemo_sk = cd_ss.cd_demo_sk
    INNER JOIN catalog_sales cs
        ON cs.cs_sold_date_sk = d_sold.d_date_sk
    INNER JOIN date_dim d_ship
        ON cs.cs_ship_date_sk = d_ship.d_date_sk
    INNER JOIN catalog_page cp
        ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
        AND cp.cp_start_date_sk = d_ship.d_date_sk
    INNER JOIN ship_mode sm
        ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    INNER JOIN warehouse w
        ON cs.cs_warehouse_sk = w.w_warehouse_sk
    INNER JOIN inventory i
        ON i.inv_date_sk = d_sold.d_date_sk
        AND i.inv_warehouse_sk = w.w_warehouse_sk
    INNER JOIN customer_address ca_bill
        ON cs.cs_bill_addr_sk = ca_bill.ca_address_sk
    INNER JOIN customer_address ca_ship
        ON cs.cs_ship_addr_sk = ca_ship.ca_address_sk
    INNER JOIN customer_demographics cd_bill
        ON cs.cs_bill_cdemo_sk = cd_bill.cd_demo_sk
    INNER JOIN customer_demographics cd_ship
        ON cs.cs_ship_cdemo_sk = cd_ship.cd_demo_sk
    INNER JOIN web_page wp
        ON wp.wp_creation_date_sk = d_sold.d_date_sk
    WHERE d_sold.d_year = 2001
      AND s.s_state = 'CA'
      AND sm.sm_type = 'AIR'
      AND wp.wp_max_ad_count BETWEEN 1 AND 3
),
aggregated AS (
    SELECT
        s_state,
        d_year,
        SUM(cs_sales) AS total_catalog_sales,
        SUM(ss_sales) AS total_store_sales,
        SUM(cs_sales + ss_sales) AS total_sales,
        SUM(cs_profit) AS total_profit,
        SUM(inv_qty) AS total_inventory,
        CASE 
            WHEN SUM(cs_profit) > 100000 THEN 'HIGH'
            WHEN SUM(cs_profit) BETWEEN 50000 AND 100000 THEN 'MEDIUM'
            ELSE 'LOW'
        END AS profit_category
    FROM joined_data
    GROUP BY ROLLUP (s_state, d_year)
),
ranked AS (
    SELECT
        s_state,
        d_year,
        total_catalog_sales,
        total_store_sales,
        total_sales,
        total_profit,
        total_inventory,
        profit_category,
        ROW_NUMBER() OVER (PARTITION BY s_state ORDER BY total_sales DESC) AS sales_rank
    FROM aggregated
)
SELECT
    s_state,
    d_year,
    total_catalog_sales,
    total_store_sales,
    total_sales,
    total_profit,
    total_inventory,
    profit_category,
    sales_rank
FROM ranked
EXCEPT
SELECT
    s_state,
    d_year,
    total_catalog_sales,
    total_store_sales,
    total_sales,
    total_profit,
    total_inventory,
    profit_category,
    sales_rank
FROM ranked
WHERE total_inventory = 0
ORDER BY s_state, d_year
LIMIT 100

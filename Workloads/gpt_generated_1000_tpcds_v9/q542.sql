/* Goal: Calculate total catalog and store sales, profit, and order counts by department, brand, city, and year for a specific day, using all TPC‑DS tables. */
WITH sales_data AS (
    SELECT
        cp.cp_department                     AS cp_department,
        i.i_brand                            AS i_brand,
        w.w_city                             AS w_city,
        d_sold.d_year                        AS d_year,
        cs.cs_ext_sales_price                AS catalog_sales_amount,
        cs.cs_net_profit                     AS catalog_profit,
        ss.ss_ext_sales_price                AS store_sales_amount,
        ss.ss_net_profit                     AS store_profit,
        cs.cs_order_number                   AS cs_order_number,
        ss.ss_ticket_number                  AS ss_ticket_number
    FROM catalog_sales cs
    JOIN catalog_page cp
        ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN item i
        ON cs.cs_item_sk = i.i_item_sk
    JOIN promotion p
        ON cs.cs_promo_sk = p.p_promo_sk
    JOIN warehouse w
        ON cs.cs_warehouse_sk = w.w_warehouse_sk
    JOIN date_dim d_sold
        ON cs.cs_sold_date_sk = d_sold.d_date_sk
    JOIN time_dim t_sold
        ON cs.cs_sold_time_sk = t_sold.t_time_sk
    JOIN customer_demographics cd_bill
        ON cs.cs_bill_cdemo_sk = cd_bill.cd_demo_sk
    JOIN household_demographics hd_bill
        ON cs.cs_bill_hdemo_sk = hd_bill.hd_demo_sk
    JOIN date_dim d_ship
        ON cs.cs_ship_date_sk = d_ship.d_date_sk
    JOIN date_dim d_cp_start
        ON cp.cp_start_date_sk = d_cp_start.d_date_sk
    JOIN date_dim d_cp_end
        ON cp.cp_end_date_sk = d_cp_end.d_date_sk
    JOIN income_band ib
        ON hd_bill.hd_income_band_sk = ib.ib_income_band_sk
    LEFT JOIN store_sales ss
        ON ss.ss_item_sk = i.i_item_sk
        AND ss.ss_sold_date_sk = d_sold.d_date_sk
        AND ss.ss_sold_time_sk = t_sold.t_time_sk
    LEFT JOIN web_page wp
        ON wp.wp_creation_date_sk = d_sold.d_date_sk
    LEFT JOIN web_site ws
        ON ws.web_open_date_sk = d_sold.d_date_sk
    WHERE
        w.w_city = 'Pleasant Hill'
        AND i.i_brand = 'BrandA'
        AND d_sold.d_year = 2001
        AND d_sold.d_date = DATE '2001-01-15'
        AND p.p_discount_active = 'Y'
)
SELECT
    cp_department,
    i_brand,
    w_city,
    d_year,
    SUM(COALESCE(catalog_sales_amount, 0)) AS total_catalog_sales,
    SUM(COALESCE(store_sales_amount, 0))   AS total_store_sales,
    SUM(COALESCE(catalog_profit, 0) + COALESCE(store_profit, 0)) AS total_profit,
    COUNT(DISTINCT cs_order_number) AS catalog_order_count,
    COUNT(DISTINCT ss_ticket_number) AS store_ticket_count
FROM sales_data
GROUP BY CUBE (cp_department, i_brand, w_city, d_year)
ORDER BY cp_department, i_brand, w_city, d_year
LIMIT 100

WITH date_filtered AS (
    SELECT
        d_date_sk,
        d_year,
        d_month_seq,
        d_quarter_seq,
        d_holiday
    FROM date_dim
    WHERE d_year = 2001
      AND d_holiday = 'N'
      AND d_month_seq BETWEEN 1200 AND 1212
      AND d_quarter_seq = 4000
)
SELECT
    d_year,
    i_category,
    cp_department,
    ship_type,
    total_sales,
    avg_discount,
    distinct_orders,
    total_return_amount,
    min_sales_price,
    max_sales_price
FROM (
    SELECT
        d.d_year,
        i.i_category,
        cp.cp_department,
        sm.sm_type AS ship_type,
        SUM(cs.cs_ext_sales_price) AS total_sales,
        AVG(cs.cs_ext_discount_amt) AS avg_discount,
        COUNT(DISTINCT cs.cs_order_number) AS distinct_orders,
        SUM(CASE WHEN cr.cr_return_quantity > 0 THEN cr.cr_return_amount ELSE 0 END) AS total_return_amount,
        MIN(cs.cs_sales_price) AS min_sales_price,
        MAX(cs.cs_sales_price) AS max_sales_price
    FROM catalog_sales cs
    JOIN date_filtered d ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    LEFT JOIN catalog_returns cr ON cr.cr_order_number = cs.cs_order_number
    WHERE i.i_brand = 'Brand#12'
      AND i.i_color = 'Red'
      AND cp.cp_department = 'Electronics'
      AND sm.sm_carrier = 'CarrierX'
    GROUP BY d.d_year, i.i_category, cp.cp_department, sm.sm_type
    UNION ALL
    SELECT
        d.d_year,
        i.i_category,
        CAST(NULL AS varchar) AS cp_department,
        CAST(NULL AS varchar) AS ship_type,
        SUM(ss.ss_ext_sales_price) AS total_sales,
        AVG(ss.ss_ext_discount_amt) AS avg_discount,
        COUNT(DISTINCT ss.ss_ticket_number) AS distinct_orders,
        SUM(CASE WHEN sr.sr_return_quantity > 0 THEN sr.sr_return_amt ELSE 0 END) AS total_return_amount,
        MIN(ss.ss_sales_price) AS min_sales_price,
        MAX(ss.ss_sales_price) AS max_sales_price
    FROM store_sales ss
    JOIN date_filtered d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    JOIN store_returns sr ON sr.sr_ticket_number = ss.ss_ticket_number
        AND sr.sr_item_sk = ss.ss_item_sk
    JOIN inventory inv ON inv.inv_date_sk = d.d_date_sk
        AND inv.inv_item_sk = i.i_item_sk
    JOIN web_page wp ON wp.wp_access_date_sk = d.d_date_sk
    WHERE s.s_state = 'CA'
      AND i.i_size = 'M'
      AND inv.inv_quantity_on_hand > 0
      AND wp.wp_type = 'Home'
    GROUP BY d.d_year, i.i_category
) AS combined
LIMIT 100

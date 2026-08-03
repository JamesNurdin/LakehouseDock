WITH
    inv_agg AS (
        SELECT
            inv_item_sk,
            inv_warehouse_sk,
            inv_date_sk,
            SUM(inv_quantity_on_hand) AS total_qty
        FROM inventory
        GROUP BY inv_item_sk, inv_warehouse_sk, inv_date_sk
    ),
    cust_from_sales AS (
        SELECT DISTINCT ss_customer_sk AS cust_sk
        FROM store_sales ss
        JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
        WHERE d.d_year = 2000
    ),
    cust_from_returns AS (
        SELECT DISTINCT cr_refunded_customer_sk AS cust_sk
        FROM catalog_returns cr
        JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
        WHERE d.d_year = 2000
    ),
    intersect_customers AS (
        SELECT cust_sk FROM cust_from_sales
        INTERSECT
        SELECT cust_sk FROM cust_from_returns
    )
SELECT
    agg.c_customer_id,
    agg.d_year,
    agg.i_brand,
    agg.cp_department,
    agg.total_sales,
    agg.avg_return_amount,
    agg.distinct_tickets,
    agg.min_price,
    agg.max_price,
    agg.total_net_loss,
    ROW_NUMBER() OVER (PARTITION BY agg.c_customer_id ORDER BY agg.total_sales DESC) AS rn
FROM (
    SELECT
        c.c_customer_id,
        d.d_year,
        i.i_brand,
        cp.cp_department,
        SUM(ss.ss_net_paid) AS total_sales,
        AVG(cr.cr_return_amount) AS avg_return_amount,
        COUNT(DISTINCT ss.ss_ticket_number) AS distinct_tickets,
        MIN(ss.ss_sales_price) AS min_price,
        MAX(ss.ss_sales_price) AS max_price,
        SUM(CASE WHEN cr.cr_net_loss > 0 THEN cr.cr_net_loss ELSE 0 END) AS total_net_loss
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN time_dim t ON ss.ss_sold_time_sk = t.t_time_sk
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
    JOIN customer_demographics cd ON ss.ss_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
    JOIN customer_address ca ON ss.ss_addr_sk = ca.ca_address_sk
    JOIN store_returns sr ON ss.ss_ticket_number = sr.sr_ticket_number
    JOIN catalog_returns cr ON cr.cr_item_sk = i.i_item_sk AND cr.cr_returned_date_sk = d.d_date_sk
    JOIN catalog_page cp ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN warehouse w ON cr.cr_warehouse_sk = w.w_warehouse_sk
    JOIN inv_agg ia ON ia.inv_item_sk = i.i_item_sk AND ia.inv_warehouse_sk = w.w_warehouse_sk AND ia.inv_date_sk = d.d_date_sk
    JOIN web_page wp ON wp.wp_customer_sk = c.c_customer_sk AND wp.wp_creation_date_sk = d.d_date_sk
    JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    WHERE d.d_year = 2000
      AND ca.ca_country = 'United States'
      AND i.i_brand = 'Brand#12'
      AND wp.wp_max_ad_count > 2
      AND cp.cp_department = 'Books'
      AND c.c_customer_sk IN (SELECT cust_sk FROM intersect_customers)
    GROUP BY
        c.c_customer_id,
        d.d_year,
        i.i_brand,
        cp.cp_department
) agg
ORDER BY agg.total_sales DESC
LIMIT 100

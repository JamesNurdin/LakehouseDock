WITH base AS (
    SELECT
        i.i_brand_id,
        i.i_brand,
        d_sold.d_year,
        i.i_color,
        CASE WHEN i.i_color = 'Red' THEN 'Red' ELSE 'Other' END AS color_category,
        SUM(ss.ss_net_paid) AS store_sales_net_paid,
        SUM(ws.ws_net_paid) AS web_sales_net_paid,
        SUM(cr.cr_net_loss) AS catalog_returns_net_loss,
        SUM(inv.inv_quantity_on_hand) AS total_inventory,
        COUNT(DISTINCT c.c_customer_sk) AS distinct_customers,
        (SUM(ss.ss_net_paid) + SUM(ws.ws_net_paid) - SUM(cr.cr_net_loss)) / NULLIF(SUM(inv.inv_quantity_on_hand), 0) AS net_per_inventory
    FROM
        store_sales ss
        JOIN date_dim d_sold ON ss.ss_sold_date_sk = d_sold.d_date_sk
        JOIN time_dim t_sold ON ss.ss_sold_time_sk = t_sold.t_time_sk
        JOIN item i ON ss.ss_item_sk = i.i_item_sk
        JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
        JOIN customer_address ca ON ss.ss_addr_sk = ca.ca_address_sk
        JOIN catalog_returns cr ON cr.cr_item_sk = i.i_item_sk
        JOIN date_dim d_return ON cr.cr_returned_date_sk = d_return.d_date_sk
        JOIN time_dim t_return ON cr.cr_returned_time_sk = t_return.t_time_sk
        JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
        JOIN catalog_page cp ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
        JOIN date_dim d_cp_start ON cp.cp_start_date_sk = d_cp_start.d_date_sk
        JOIN date_dim d_cp_end ON cp.cp_end_date_sk = d_cp_end.d_date_sk
        JOIN web_sales ws ON ws.ws_item_sk = i.i_item_sk
        JOIN date_dim d_ws_sold ON ws.ws_sold_date_sk = d_ws_sold.d_date_sk
        JOIN time_dim t_ws_sold ON ws.ws_sold_time_sk = t_ws_sold.t_time_sk
        JOIN date_dim d_ws_ship ON ws.ws_ship_date_sk = d_ws_ship.d_date_sk
        JOIN web_site ws_site ON ws.ws_web_site_sk = ws_site.web_site_sk
        JOIN inventory inv ON inv.inv_item_sk = i.i_item_sk
        JOIN date_dim d_inv ON inv.inv_date_sk = d_inv.d_date_sk
        JOIN customer_address ca_ws_bill ON ws.ws_bill_addr_sk = ca_ws_bill.ca_address_sk
        JOIN customer_address ca_ws_ship ON ws.ws_ship_addr_sk = ca_ws_ship.ca_address_sk
        JOIN customer c_ws_bill ON ws.ws_bill_customer_sk = c_ws_bill.c_customer_sk
        JOIN customer c_ws_ship ON ws.ws_ship_customer_sk = c_ws_ship.c_customer_sk
        JOIN customer c_refunded ON cr.cr_refunded_customer_sk = c_refunded.c_customer_sk
        JOIN customer c_returning ON cr.cr_returning_customer_sk = c_returning.c_customer_sk
        JOIN customer_address ca_refunded ON cr.cr_refunded_addr_sk = ca_refunded.ca_address_sk
        JOIN customer_address ca_returning ON cr.cr_returning_addr_sk = ca_returning.ca_address_sk
    WHERE
        d_sold.d_year = 2001
        AND i.i_brand_id = 1003001
        AND ca.ca_state = 'CA'
        AND r.r_reason_desc = 'Damaged'
        AND cp.cp_department = 'Electronics'
        AND ws_site.web_country = 'United States'
        AND inv.inv_quantity_on_hand > 0
    GROUP BY
        i.i_brand_id,
        i.i_brand,
        d_sold.d_year,
        i.i_color
)
SELECT
    i_brand,
    SUM(store_sales_net_paid) AS total_store_sales,
    SUM(web_sales_net_paid) AS total_web_sales,
    SUM(catalog_returns_net_loss) AS total_returns_loss,
    SUM(total_inventory) AS total_inventory,
    COUNT(DISTINCT distinct_customers) AS total_distinct_customers,
    AVG(net_per_inventory) AS avg_net_per_inventory
FROM base
WHERE store_sales_net_paid > 1000
GROUP BY i_brand
HAVING SUM(store_sales_net_paid) > 5000
ORDER BY avg_net_per_inventory DESC
LIMIT 100

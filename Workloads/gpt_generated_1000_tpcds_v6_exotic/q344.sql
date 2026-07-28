WITH all_data AS (
    SELECT
        d.d_date,
        d.d_year,
        i.i_item_id,
        i.i_brand,
        c.c_salutation,
        ca.ca_state,
        s.s_state,
        sm.sm_type,
        cp.cp_department,
        inv.inv_quantity_on_hand,
        ss.ss_net_paid,
        ss.ss_ticket_number,
        cr.cr_net_loss,
        cr.cr_return_quantity
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
    JOIN customer_address ca ON ss.ss_addr_sk = ca.ca_address_sk
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    JOIN catalog_sales cs ON cs.cs_item_sk = i.i_item_sk
    JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN web_sales ws ON ws.ws_item_sk = i.i_item_sk
    JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
    JOIN web_site wsit ON ws.ws_web_site_sk = wsit.web_site_sk
    JOIN inventory inv ON inv.inv_item_sk = i.i_item_sk AND inv.inv_date_sk = d.d_date_sk
    JOIN catalog_returns cr ON cr.cr_order_number = cs.cs_order_number AND cr.cr_item_sk = i.i_item_sk
    JOIN web_returns wr ON wr.wr_order_number = ws.ws_order_number AND wr.wr_item_sk = i.i_item_sk
    WHERE d.d_year = 2001
      AND i.i_brand = 'Brand#12'
      AND c.c_salutation = 'Ms.'
      AND s.s_state = 'CA'
      AND sm.sm_type = 'AIR'
      AND cp.cp_department = 'Electronics'
      AND inv.inv_quantity_on_hand > 500
),
sales_agg AS (
    SELECT
        'sales' AS record_type,
        d_date,
        i_item_id,
        SUM(ss_net_paid) AS total_amount,
        COUNT(DISTINCT ss_ticket_number) AS txn_count
    FROM all_data
    WHERE ss_ticket_number IS NOT NULL
    GROUP BY d_date, i_item_id
),
returns_agg AS (
    SELECT
        'returns' AS record_type,
        d_date,
        i_item_id,
        SUM(cr_net_loss) AS total_amount,
        COUNT(*) AS txn_count
    FROM all_data
    WHERE cr_return_quantity IS NOT NULL
    GROUP BY d_date, i_item_id
)
SELECT *
FROM sales_agg
UNION ALL
SELECT *
FROM returns_agg
ORDER BY record_type, total_amount DESC
LIMIT 100

SELECT *
FROM (
    SELECT
        d.d_year,
        d.d_month_seq,
        c.c_customer_id,
        i.i_category,
        CASE WHEN d.d_dow IN (0, 6) THEN 'Weekend' ELSE 'Weekday' END AS day_type,
        SUM(sr.sr_return_amt) AS total_return_amt,
        SUM(CASE WHEN sr.sr_return_quantity > 5 THEN sr.sr_return_amt ELSE 0 END) AS high_qty_return_amt,
        COUNT(DISTINCT i.i_item_id) AS distinct_items,
        COUNT(DISTINCT sr.sr_ticket_number) AS distinct_tickets,
        MAX(cc_open.cc_name) AS open_cc_name,
        MAX(cc_closed.cc_name) AS closed_cc_name,
        MAX(cp_start.cp_type) AS catalog_start_type,
        MAX(cp_end.cp_type) AS catalog_end_type,
        MAX(wp_creation.wp_type) AS wp_creation_type,
        MAX(wp_access.wp_type) AS wp_access_type,
        MAX(wp_customer.wp_type) AS wp_customer_type
    FROM store_returns sr
    JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
    JOIN time_dim t ON sr.sr_return_time_sk = t.t_time_sk
    JOIN item i ON sr.sr_item_sk = i.i_item_sk
    JOIN customer c ON sr.sr_customer_sk = c.c_customer_sk
    LEFT JOIN inventory inv_date ON inv_date.inv_date_sk = d.d_date_sk
    LEFT JOIN inventory inv_item ON inv_item.inv_item_sk = i.i_item_sk
    LEFT JOIN call_center cc_open ON cc_open.cc_open_date_sk = d.d_date_sk
    LEFT JOIN call_center cc_closed ON cc_closed.cc_closed_date_sk = d.d_date_sk
    LEFT JOIN catalog_page cp_start ON cp_start.cp_start_date_sk = d.d_date_sk
    LEFT JOIN catalog_page cp_end ON cp_end.cp_end_date_sk = d.d_date_sk
    LEFT JOIN web_page wp_creation ON wp_creation.wp_creation_date_sk = d.d_date_sk
    LEFT JOIN web_page wp_access ON wp_access.wp_access_date_sk = d.d_date_sk
    LEFT JOIN web_page wp_customer ON wp_customer.wp_customer_sk = c.c_customer_sk
    WHERE d.d_year = 2001
    GROUP BY d.d_year,
             d.d_month_seq,
             c.c_customer_id,
             i.i_category,
             CASE WHEN d.d_dow IN (0, 6) THEN 'Weekend' ELSE 'Weekday' END
    UNION ALL
    SELECT
        d.d_year,
        d.d_month_seq,
        c.c_customer_id,
        i.i_category,
        CASE WHEN d.d_dow IN (0, 6) THEN 'Weekend' ELSE 'Weekday' END AS day_type,
        SUM(sr.sr_return_amt) AS total_return_amt,
        SUM(CASE WHEN sr.sr_return_quantity > 5 THEN sr.sr_return_amt ELSE 0 END) AS high_qty_return_amt,
        COUNT(DISTINCT i.i_item_id) AS distinct_items,
        COUNT(DISTINCT sr.sr_ticket_number) AS distinct_tickets,
        MAX(cc_open.cc_name) AS open_cc_name,
        MAX(cc_closed.cc_name) AS closed_cc_name,
        MAX(cp_start.cp_type) AS catalog_start_type,
        MAX(cp_end.cp_type) AS catalog_end_type,
        MAX(wp_creation.wp_type) AS wp_creation_type,
        MAX(wp_access.wp_type) AS wp_access_type,
        MAX(wp_customer.wp_type) AS wp_customer_type
    FROM store_returns sr
    JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
    JOIN time_dim t ON sr.sr_return_time_sk = t.t_time_sk
    JOIN item i ON sr.sr_item_sk = i.i_item_sk
    JOIN customer c ON sr.sr_customer_sk = c.c_customer_sk
    LEFT JOIN inventory inv_date ON inv_date.inv_date_sk = d.d_date_sk
    LEFT JOIN inventory inv_item ON inv_item.inv_item_sk = i.i_item_sk
    LEFT JOIN call_center cc_open ON cc_open.cc_open_date_sk = d.d_date_sk
    LEFT JOIN call_center cc_closed ON cc_closed.cc_closed_date_sk = d.d_date_sk
    LEFT JOIN catalog_page cp_start ON cp_start.cp_start_date_sk = d.d_date_sk
    LEFT JOIN catalog_page cp_end ON cp_end.cp_end_date_sk = d.d_date_sk
    LEFT JOIN web_page wp_creation ON wp_creation.wp_creation_date_sk = d.d_date_sk
    LEFT JOIN web_page wp_access ON wp_access.wp_access_date_sk = d.d_date_sk
    LEFT JOIN web_page wp_customer ON wp_customer.wp_customer_sk = c.c_customer_sk
    WHERE d.d_year = 2002
    GROUP BY d.d_year,
             d.d_month_seq,
             c.c_customer_id,
             i.i_category,
             CASE WHEN d.d_dow IN (0, 6) THEN 'Weekend' ELSE 'Weekday' END
) AS combined
LIMIT 100

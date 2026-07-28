/* goal: Analyze sales and returns performance by year, customer and return reason, focusing on a specific year, location type, GMT offset, and inventory item */
WITH joined_data AS (
    SELECT
        d.d_year,
        c.c_customer_id,
        r.r_reason_desc,
        ss.ss_net_paid,
        cr.cr_return_amount,
        ss.ss_ticket_number,
        i.inv_quantity_on_hand,
        cc.cc_tax_percentage,
        ib.ib_upper_bound
    FROM tpcds.date_dim d
    JOIN tpcds.store_sales ss
        ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN tpcds.time_dim t
        ON ss.ss_sold_time_sk = t.t_time_sk
    JOIN tpcds.customer c
        ON ss.ss_customer_sk = c.c_customer_sk
    JOIN tpcds.customer_demographics cd
        ON ss.ss_cdemo_sk = cd.cd_demo_sk
    JOIN tpcds.household_demographics hd
        ON ss.ss_hdemo_sk = hd.hd_demo_sk
    JOIN tpcds.customer_address ca
        ON ss.ss_addr_sk = ca.ca_address_sk
    JOIN tpcds.inventory i
        ON i.inv_date_sk = d.d_date_sk
    JOIN tpcds.call_center cc
        ON cc.cc_open_date_sk = d.d_date_sk
    JOIN tpcds.catalog_page cp
        ON cp.cp_start_date_sk = d.d_date_sk
    JOIN tpcds.catalog_returns cr
        ON cr.cr_returned_date_sk = d.d_date_sk
    JOIN tpcds.reason r
        ON cr.cr_reason_sk = r.r_reason_sk
    JOIN tpcds.income_band ib
        ON hd.hd_income_band_sk = ib.ib_income_band_sk
    WHERE d.d_year = 2001
      AND ca.ca_location_type = 'condo'
      AND cc.cc_gmt_offset = -6.00
      AND i.inv_item_sk = 101416
)
SELECT
    d_year,
    c_customer_id,
    r_reason_desc,
    SUM(ss_net_paid)               AS total_sales,
    SUM(cr_return_amount)          AS total_return_amount,
    COUNT(DISTINCT ss_ticket_number) AS distinct_tickets,
    AVG(inv_quantity_on_hand)      AS avg_inventory_qty,
    MIN(cc_tax_percentage)         AS min_tax_pct,
    MAX(ib_upper_bound)            AS max_income_upper
FROM joined_data
GROUP BY ROLLUP (d_year, c_customer_id, r_reason_desc)
ORDER BY total_sales DESC
LIMIT 100

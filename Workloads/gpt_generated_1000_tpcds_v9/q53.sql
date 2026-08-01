SELECT
    s.s_store_name,
    s.s_city,
    d.d_year,
    SUM(ss.ss_ext_sales_price) AS total_store_sales,
    SUM(cr.cr_return_amount) AS total_catalog_return_amount,
    SUM(wr.wr_return_amt) AS total_web_return_amount,
    SUM(inv.inv_quantity_on_hand) AS total_inventory_quantity,
    COUNT(DISTINCT ss.ss_ticket_number) AS distinct_sales_tickets,
    AVG(i.i_current_price) AS avg_item_price,
    MIN(i.i_current_price) AS min_item_price,
    MAX(i.i_current_price) AS max_item_price
FROM store_sales ss
JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
JOIN item i ON ss.ss_item_sk = i.i_item_sk
JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
JOIN customer_address ca ON ss.ss_addr_sk = ca.ca_address_sk
JOIN store s ON ss.ss_store_sk = s.s_store_sk
JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
JOIN inventory inv ON inv.inv_item_sk = i.i_item_sk AND inv.inv_date_sk = d.d_date_sk
JOIN warehouse w ON inv.inv_warehouse_sk = w.w_warehouse_sk
JOIN catalog_returns cr ON cr.cr_returned_date_sk = d.d_date_sk AND cr.cr_item_sk = i.i_item_sk
JOIN call_center cc ON cr.cr_call_center_sk = cc.cc_call_center_sk
JOIN catalog_page cp ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
JOIN ship_mode sm ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
JOIN web_returns wr ON wr.wr_returned_date_sk = d.d_date_sk AND wr.wr_item_sk = i.i_item_sk
WHERE d.d_date >= DATE '2021-01-01'
  AND d.d_date < DATE '2022-01-01'
  AND s.s_state = 'TX'
  AND cc.cc_state = 'WA'
  AND i.i_current_price > 100.00
  AND c.c_birth_year BETWEEN 1960 AND 1970
  AND NOT EXISTS (
        SELECT 1
        FROM catalog_returns cr2
        WHERE cr2.cr_refunded_customer_sk = c.c_customer_sk
          AND cr2.cr_return_amount > 5000
    )
GROUP BY s.s_store_name, s.s_city, d.d_year
ORDER BY total_store_sales DESC, s.s_store_name ASC
LIMIT 100

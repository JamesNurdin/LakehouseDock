WITH filtered_stores AS (
    SELECT s1.s_store_id
    FROM store s1
    WHERE s1.s_state = 'TX' AND s1.s_number_employees > 200
    INTERSECT
    SELECT s2.s_store_id
    FROM store s2
    JOIN store_sales ss2 ON s2.s_store_sk = ss2.ss_store_sk
    WHERE ss2.ss_quantity >= 5
)
SELECT
    d.d_year,
    s.s_store_name,
    p.p_promo_name,
    cp.cp_department,
    COUNT(DISTINCT ss.ss_ticket_number) AS num_sales,
    SUM(ss.ss_net_paid) AS total_net_paid,
    AVG(cs.cs_sales_price) AS avg_catalog_sales_price,
    SUM(cr.cr_return_amount) AS total_catalog_return_amount,
    SUM(sr.sr_return_amt) AS total_store_return_amount,
    SUM(inv.inv_quantity_on_hand) AS total_inventory_on_hand,
    COUNT(DISTINCT w.web_site_id) AS num_web_sites
FROM store_sales ss
JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
JOIN customer_address ca ON ss.ss_addr_sk = ca.ca_address_sk
JOIN store s ON ss.ss_store_sk = s.s_store_sk
JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
LEFT JOIN store_returns sr
    ON sr.sr_item_sk = ss.ss_item_sk
   AND sr.sr_ticket_number = ss.ss_ticket_number
   AND sr.sr_returned_date_sk = d.d_date_sk
JOIN catalog_sales cs ON cs.cs_sold_date_sk = d.d_date_sk
JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
JOIN catalog_returns cr
    ON cr.cr_item_sk = cs.cs_item_sk
   AND cr.cr_order_number = cs.cs_order_number
   AND cr.cr_returned_date_sk = d.d_date_sk
   AND cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
JOIN inventory inv ON inv.inv_date_sk = d.d_date_sk
JOIN web_site w ON w.web_open_date_sk = d.d_date_sk
WHERE
    d.d_year = 2002
    AND s.s_state = 'TX'
    AND p.p_channel_email = 'Y'
    AND c.c_preferred_cust_flag = 'Y'
    AND inv.inv_warehouse_sk = 4
    AND cp.cp_type = 'C'
    AND s.s_store_id IN (SELECT s_store_id FROM filtered_stores)
GROUP BY
    d.d_year,
    s.s_store_name,
    p.p_promo_name,
    cp.cp_department
ORDER BY total_net_paid DESC
LIMIT 100

WITH filtered_dates AS (
        SELECT d_date_sk
        FROM date_dim
        WHERE d_year = 2001
    )
SELECT
    s.s_store_name,
    cp.cp_catalog_number,
    wp.wp_type,
    r1.r_reason_desc,
    SUM( COALESCE(cr.cr_net_loss, 0) + COALESCE(sr.sr_net_loss, 0) + COALESCE(wr.wr_net_loss, 0) ) AS total_net_loss,
    COUNT(DISTINCT r1.r_reason_id) AS distinct_reason_cnt,
    AVG(inv.inv_quantity_on_hand) AS avg_inventory_qty,
    CASE
        WHEN SUM( COALESCE(cr.cr_return_quantity, 0) + COALESCE(sr.sr_return_quantity, 0) + COALESCE(wr.wr_return_quantity, 0) ) > 1000 THEN 'High Volume'
        ELSE 'Low Volume'
    END AS volume_category
FROM date_dim d
JOIN filtered_dates fd ON d.d_date_sk = fd.d_date_sk

-- Catalog Returns and related dimensions
JOIN catalog_returns cr ON cr.cr_returned_date_sk = d.d_date_sk
JOIN catalog_page cp ON cp.cp_catalog_page_sk = cr.cr_catalog_page_sk
JOIN reason r1 ON r1.r_reason_sk = cr.cr_reason_sk
JOIN customer_address ca1 ON ca1.ca_address_sk = cr.cr_refunded_addr_sk
JOIN customer_demographics cd1 ON cd1.cd_demo_sk = cr.cr_refunded_cdemo_sk

-- Store Returns and related dimensions
JOIN store_returns sr ON sr.sr_returned_date_sk = d.d_date_sk
JOIN store s ON s.s_store_sk = sr.sr_store_sk
JOIN reason r2 ON r2.r_reason_sk = sr.sr_reason_sk
JOIN customer_address ca2 ON ca2.ca_address_sk = sr.sr_addr_sk
JOIN customer_demographics cd2 ON cd2.cd_demo_sk = sr.sr_cdemo_sk

-- Web Returns and related dimensions
JOIN web_returns wr ON wr.wr_returned_date_sk = d.d_date_sk
JOIN web_page wp ON wp.wp_web_page_sk = wr.wr_web_page_sk
JOIN reason r3 ON r3.r_reason_sk = wr.wr_reason_sk
JOIN customer_address ca3 ON ca3.ca_address_sk = wr.wr_refunded_addr_sk
JOIN customer_demographics cd3 ON cd3.cd_demo_sk = wr.wr_refunded_cdemo_sk

-- Inventory (joined on the same date key as the returns)
JOIN inventory inv ON inv.inv_date_sk = d.d_date_sk

WHERE
    s.s_state = 'CA'                       -- filter 1: store in California
    AND cp.cp_department = 'Electronics'   -- filter 2: specific catalog department
    AND cp.cp_catalog_number IN (5, 11)    -- filter 3: selected catalog numbers
    AND r1.r_reason_desc LIKE '%price%'    -- filter 4: reason containing the word "price"
GROUP BY
    s.s_store_name,
    cp.cp_catalog_number,
    wp.wp_type,
    r1.r_reason_desc
ORDER BY total_net_loss DESC
LIMIT 100

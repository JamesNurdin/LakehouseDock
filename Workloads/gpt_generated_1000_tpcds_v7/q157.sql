SELECT
    d_sr.d_year,
    i.i_brand,
    cd_sr.cd_gender,
    SUM(cr.cr_return_amount) AS total_catalog_return_amount,
    SUM(sr.sr_return_amt) AS total_store_return_amt,
    AVG(inv.inv_quantity_on_hand) AS avg_inventory_on_hand,
    COUNT(DISTINCT i.i_item_id) AS distinct_items,
    MIN(d_sr.d_date) AS earliest_date,
    MAX(d_sr.d_date) AS latest_date
FROM store_returns sr
JOIN date_dim d_sr ON sr.sr_returned_date_sk = d_sr.d_date_sk
JOIN item i ON sr.sr_item_sk = i.i_item_sk
JOIN customer_demographics cd_sr ON sr.sr_cdemo_sk = cd_sr.cd_demo_sk
LEFT JOIN catalog_returns cr ON cr.cr_returned_date_sk = d_sr.d_date_sk
LEFT JOIN catalog_page cp ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
LEFT JOIN warehouse w ON cr.cr_warehouse_sk = w.w_warehouse_sk
JOIN inventory inv ON inv.inv_item_sk = i.i_item_sk
    AND inv.inv_date_sk = d_sr.d_date_sk
    AND inv.inv_warehouse_sk = w.w_warehouse_sk
JOIN web_page wp ON wp.wp_creation_date_sk = d_sr.d_date_sk
JOIN web_site ws ON ws.web_open_date_sk = d_sr.d_date_sk
WHERE d_sr.d_year = 2001
  AND i.i_brand = 'Brand#12'
  AND cd_sr.cd_gender = 'M'
  AND cd_sr.cd_education_status = 'Advanced Degree'
  AND inv.inv_quantity_on_hand > 400
  AND wp.wp_autogen_flag = 'N'
  AND w.w_state = 'CA'
GROUP BY d_sr.d_year, i.i_brand, cd_sr.cd_gender
ORDER BY total_catalog_return_amount DESC, total_store_return_amt DESC
LIMIT 100

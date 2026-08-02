WITH items_only_in_store AS (
    SELECT sr_item_sk FROM store_returns
    EXCEPT
    SELECT cr_item_sk FROM catalog_returns
)
SELECT
    w.w_county,
    d.d_year,
    i.i_brand,
    COUNT(DISTINCT i.i_item_id) AS distinct_items,
    SUM(sr.sr_return_amt) AS total_store_return,
    AVG(cr.cr_return_amount) AS avg_catalog_return,
    MIN(sr.sr_return_amt) AS min_store_return,
    MAX(sr.sr_return_amt) AS max_store_return,
    SUM(CASE WHEN sr.sr_return_amt > 100 THEN sr.sr_return_amt ELSE 0 END) AS high_return_total,
    (SELECT AVG(i2.i_current_price) FROM item i2 WHERE i2.i_brand = i.i_brand) AS avg_price_by_brand
FROM store_returns sr
JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
JOIN time_dim t ON sr.sr_return_time_sk = t.t_time_sk
JOIN item i ON sr.sr_item_sk = i.i_item_sk
JOIN customer c ON sr.sr_customer_sk = c.c_customer_sk
JOIN customer_address ca ON sr.sr_addr_sk = ca.ca_address_sk
JOIN catalog_returns cr ON cr.cr_item_sk = i.i_item_sk
    AND cr.cr_returned_date_sk = d.d_date_sk
    AND cr.cr_returned_time_sk = t.t_time_sk
JOIN warehouse w ON cr.cr_warehouse_sk = w.w_warehouse_sk
JOIN catalog_page cp ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
JOIN inventory inv ON inv.inv_item_sk = i.i_item_sk
    AND inv.inv_date_sk = d.d_date_sk
    AND inv.inv_warehouse_sk = w.w_warehouse_sk
WHERE d.d_year = 2001
  AND w.w_county = 'Williamson County'
  AND ca.ca_gmt_offset = -8.00
  AND i.i_current_price > 100.00
  AND cp.cp_start_date_sk = 2451145
  AND sr.sr_item_sk IN (SELECT sr_item_sk FROM items_only_in_store)
GROUP BY CUBE (w.w_county, d.d_year, i.i_brand)
ORDER BY w.w_county ASC, d.d_year DESC, total_store_return DESC
LIMIT 100

WITH inv_agg AS (
    SELECT inv_date_sk,
           SUM(inv_quantity_on_hand) AS total_qty,
           AVG(inv_quantity_on_hand) AS avg_qty
    FROM inventory
    WHERE inv_quantity_on_hand > 0
    GROUP BY inv_date_sk
)
SELECT
    d.d_date AS return_date,
    cc.cc_name,
    ws.web_name,
    cp.cp_catalog_page_number,
    SUM(sr.sr_return_amt_inc_tax) AS total_return_amt_inc_tax,
    AVG(sr.sr_return_amt_inc_tax) AS avg_return_amt_inc_tax,
    COUNT(DISTINCT sr.sr_ticket_number) AS return_count,
    MIN(sr.sr_return_amt_inc_tax) AS min_return_amt_inc_tax,
    MAX(sr.sr_return_amt_inc_tax) AS max_return_amt_inc_tax,
    inv_agg.total_qty,
    ROW_NUMBER() OVER (ORDER BY SUM(sr.sr_return_amt_inc_tax) DESC) AS row_num
FROM store_returns sr
JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
JOIN call_center cc ON cc.cc_open_date_sk = d.d_date_sk
JOIN catalog_page cp ON cp.cp_start_date_sk = d.d_date_sk
JOIN web_site ws ON ws.web_open_date_sk = d.d_date_sk
JOIN inv_agg ON inv_agg.inv_date_sk = d.d_date_sk
WHERE d.d_year = 2000
  AND cc.cc_zip = '33451'
  AND sr.sr_return_ship_cost > 100.00
GROUP BY d.d_date, cc.cc_name, ws.web_name, cp.cp_catalog_page_number, inv_agg.total_qty

UNION

SELECT
    d.d_date AS return_date,
    cc.cc_name,
    ws.web_name,
    cp.cp_catalog_page_number,
    SUM(sr.sr_return_amt_inc_tax) AS total_return_amt_inc_tax,
    AVG(sr.sr_return_amt_inc_tax) AS avg_return_amt_inc_tax,
    COUNT(DISTINCT sr.sr_ticket_number) AS return_count,
    MIN(sr.sr_return_amt_inc_tax) AS min_return_amt_inc_tax,
    MAX(sr.sr_return_amt_inc_tax) AS max_return_amt_inc_tax,
    inv_agg.total_qty,
    ROW_NUMBER() OVER (ORDER BY SUM(sr.sr_return_amt_inc_tax) DESC) AS row_num
FROM store_returns sr
JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
JOIN call_center cc ON cc.cc_open_date_sk = d.d_date_sk
JOIN catalog_page cp ON cp.cp_start_date_sk = d.d_date_sk
JOIN web_site ws ON ws.web_open_date_sk = d.d_date_sk
JOIN inv_agg ON inv_agg.inv_date_sk = d.d_date_sk
WHERE d.d_year = 2000
  AND cc.cc_zip = '33451'
  AND sr.sr_return_ship_cost <= 100.00
GROUP BY d.d_date, cc.cc_name, ws.web_name, cp.cp_catalog_page_number, inv_agg.total_qty
LIMIT 100

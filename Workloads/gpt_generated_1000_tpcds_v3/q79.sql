WITH filtered_cc AS (
    SELECT DISTINCT
        cc.cc_call_center_sk,
        cc.cc_call_center_id,
        cc.cc_market_manager,
        cc.cc_mkt_desc,
        cc.cc_name,
        cc.cc_city,
        cc.cc_state,
        d.d_date_sk,
        d.d_year,
        d.d_quarter_seq,
        d.d_date
    FROM call_center cc
    JOIN date_dim d ON cc.cc_open_date_sk = d.d_date_sk
    WHERE REGEXP_LIKE(cc.cc_market_manager, 'Smith')
      AND cc.cc_name LIKE '%Call%'
)
SELECT
    fc.cc_call_center_id,
    CONCAT(fc.cc_city, ', ', fc.cc_state) AS location,
    fc.d_year,
    fc.d_quarter_seq,
    REGEXP_EXTRACT(fc.cc_mkt_desc, '^([^ ]+)', 1) AS mkt_desc_first_word,
    SUM(sr.sr_return_amt) AS total_return_amount,
    SUM(sr.sr_return_quantity) AS total_return_quantity,
    AVG(i.inv_quantity_on_hand) AS avg_inventory_qty,
    (SELECT MAX(i2.inv_quantity_on_hand) FROM inventory i2 WHERE i2.inv_date_sk = fc.d_date_sk) AS max_inventory_qty_for_date,
    (SELECT SUM(i3.inv_quantity_on_hand) FROM inventory i3 WHERE i3.inv_date_sk = fc.d_date_sk) AS total_inventory_qty_for_date
FROM filtered_cc fc
JOIN inventory i ON i.inv_date_sk = fc.d_date_sk
JOIN store_returns sr ON sr.sr_returned_date_sk = fc.d_date_sk
WHERE EXISTS (
    SELECT 1 FROM inventory i4 WHERE i4.inv_date_sk = fc.d_date_sk AND i4.inv_quantity_on_hand > 500
)
GROUP BY
    fc.cc_call_center_id,
    fc.cc_city,
    fc.cc_state,
    fc.d_year,
    fc.d_quarter_seq,
    fc.cc_mkt_desc,
    fc.d_date_sk
ORDER BY total_return_amount DESC
LIMIT 100

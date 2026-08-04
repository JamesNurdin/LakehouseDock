WITH
    filtered_store_returns AS (
        SELECT
            sr.sr_returned_date_sk,
            sr.sr_return_quantity,
            sr.sr_return_amt,
            sr.sr_return_tax,
            sr.sr_return_ship_cost,
            sr.sr_hdemo_sk,
            sr.sr_store_sk,
            d.d_date_sk,
            d.d_year,
            d.d_month_seq,
            d.d_dom
        FROM tpcds.store_returns sr
        JOIN tpcds.date_dim d
          ON sr.sr_returned_date_sk = d.d_date_sk
        WHERE d.d_year = 2001
          AND d.d_month_seq BETWEEN 1200 AND 1220
          AND sr.sr_return_tax > 2.0
          AND sr.sr_return_quantity >= 20
          AND sr.sr_return_ship_cost < 200
    ),
    filtered_call_center AS (
        SELECT
            cc.cc_call_center_sk,
            cc.cc_closed_date_sk,
            cc.cc_gmt_offset,
            cc.cc_call_center_id,
            d2.d_year AS cc_year
        FROM tpcds.call_center cc
        JOIN tpcds.date_dim d2
          ON cc.cc_closed_date_sk = d2.d_date_sk
        WHERE cc.cc_gmt_offset BETWEEN -5.00 AND 0.00
          AND d2.d_year = 2001
    ),
    filtered_inventory AS (
        SELECT
            inv.inv_item_sk,
            inv.inv_warehouse_sk,
            inv.inv_quantity_on_hand,
            d3.d_date_sk AS inv_date_sk,
            d3.d_year AS inv_year
        FROM tpcds.inventory inv
        JOIN tpcds.date_dim d3
          ON inv.inv_date_sk = d3.d_date_sk
        WHERE d3.d_year = 2001
          AND inv.inv_quantity_on_hand > 0
    ),
    warehouse_with_array AS (
        SELECT
            w.w_warehouse_sk,
            w.w_city,
            ARRAY[ w.w_street_number, w.w_suite_number ] AS addr_parts
        FROM tpcds.warehouse w
        WHERE w.w_state = 'CA'
    ),
    store_keys_a AS (
        SELECT s.s_store_sk
        FROM tpcds.store s
        WHERE s.s_state = 'CA'
    ),
    store_keys_b AS (
        SELECT s.s_store_sk
        FROM tpcds.store s
        WHERE s.s_city LIKE 'San%'
    ),
    intersected_store_keys AS (
        SELECT s_store_sk FROM store_keys_a
        INTERSECT
        SELECT s_store_sk FROM store_keys_b
    )
SELECT
    s.s_store_name,
    fsr.d_year,
    COUNT(*) AS returns_cnt,
    SUM(fsr.sr_return_amt) AS total_return_amt,
    AVG(fsr.sr_return_tax) AS avg_return_tax,
    MIN(fsr.sr_return_ship_cost) AS min_ship_cost,
    MAX(fsr.sr_return_ship_cost) AS max_ship_cost,
    MAX(cc.cc_call_center_id) AS call_center_id,
    MAX(inv.inv_quantity_on_hand) AS max_quantity_on_hand,
    MAX(w.w_city) AS warehouse_city,
    MAX(addr_part) AS address_part
FROM filtered_store_returns fsr
JOIN tpcds.household_demographics hd
  ON fsr.sr_hdemo_sk = hd.hd_demo_sk
JOIN tpcds.store s
  ON fsr.sr_store_sk = s.s_store_sk
JOIN filtered_call_center cc
  ON cc.cc_closed_date_sk = fsr.sr_returned_date_sk
JOIN filtered_inventory inv
  ON inv.inv_date_sk = fsr.sr_returned_date_sk
JOIN warehouse_with_array w
  ON inv.inv_warehouse_sk = w.w_warehouse_sk
JOIN intersected_store_keys isk
  ON s.s_store_sk = isk.s_store_sk
CROSS JOIN UNNEST(w.addr_parts) AS t (addr_part)
WHERE s.s_gmt_offset BETWEEN -6.00 AND -4.00
GROUP BY GROUPING SETS (
    (s.s_store_name, fsr.d_year),
    (s.s_store_name),
    ()
)
ORDER BY total_return_amt DESC
LIMIT 100

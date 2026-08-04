WITH inv_agg AS (
    SELECT
        inv_date_sk,
        SUM(inv_quantity_on_hand) AS total_qty,
        COUNT(*) AS cnt_items
    FROM inventory
    WHERE inv_quantity_on_hand > 500
      AND inv_warehouse_sk IN (13, 15, 2)
      AND inv_item_sk BETWEEN 101400 AND 101500
    GROUP BY inv_date_sk
),
cc_filtered AS (
    SELECT
        cc_name,
        cc_closed_date_sk,
        cc_call_center_id,
        cc_market_manager,
        cc_state,
        cc_city,
        cc_gmt_offset,
        cc_employees,
        cc_sq_ft,
        cc_mkt_desc
    FROM call_center
    WHERE cc_state = 'CA'
      AND cc_city LIKE 'San%'
      AND cc_gmt_offset BETWEEN -8.00 AND -7.00
      AND cc_employees > 50
      AND cc_sq_ft >= 2000
      AND cc_mkt_desc LIKE '%new degrees%'
)
SELECT
    cc.cc_name,
    d.d_year,
    d.d_month_seq,
    inv.total_qty,
    inv.cnt_items,
    (SELECT COUNT(*) FROM inventory i2
        WHERE i2.inv_date_sk = cc.cc_closed_date_sk
          AND i2.inv_quantity_on_hand > 600) AS high_qty_items,
    COUNT(DISTINCT cc.cc_call_center_id) AS distinct_cc
FROM date_dim d
FULL OUTER JOIN cc_filtered cc
    ON d.d_date_sk = cc.cc_closed_date_sk
FULL OUTER JOIN inv_agg inv
    ON d.d_date_sk = inv.inv_date_sk
WHERE d.d_year BETWEEN 1999 AND 2001
  AND d.d_month_seq IN (12, 13, 14)
  AND d.d_holiday = 'N'
  AND d.d_weekend = 'N'
  AND d.d_quarter_name = 'Q1'
GROUP BY
    cc.cc_name,
    d.d_year,
    d.d_month_seq,
    inv.total_qty,
    inv.cnt_items,
    cc.cc_closed_date_sk
HAVING COUNT(DISTINCT cc.cc_call_center_id) > 0

UNION DISTINCT

SELECT
    cc2.cc_name,
    d2.d_year,
    d2.d_month_seq,
    inv2.total_qty,
    inv2.cnt_items,
    (SELECT COUNT(*) FROM inventory i3
        WHERE i3.inv_date_sk = cc2.cc_closed_date_sk
          AND i3.inv_quantity_on_hand > 800) AS high_qty_items,
    COUNT(DISTINCT cc2.cc_call_center_id) AS distinct_cc
FROM date_dim d2
FULL OUTER JOIN (
    SELECT
        cc_name,
        cc_closed_date_sk,
        cc_call_center_id,
        cc_market_manager
    FROM call_center
    WHERE cc_state = 'TX'
      AND cc_city LIKE 'Hou%'
      AND cc_gmt_offset BETWEEN -6.00 AND -5.00
      AND cc_employees BETWEEN 30 AND 100
      AND cc_sq_ft BETWEEN 1500 AND 5000
      AND cc_mkt_desc LIKE '%Common%'
) cc2
    ON d2.d_date_sk = cc2.cc_closed_date_sk
FULL OUTER JOIN (
    SELECT
        inv_date_sk,
        SUM(inv_quantity_on_hand) AS total_qty,
        COUNT(*) AS cnt_items
    FROM inventory
    WHERE inv_quantity_on_hand > 700
      AND inv_warehouse_sk IN (12, 17)
    GROUP BY inv_date_sk
) inv2
    ON d2.d_date_sk = inv2.inv_date_sk
WHERE d2.d_year BETWEEN 2002 AND 2004
  AND d2.d_month_seq IN (15, 16, 17)
  AND d2.d_holiday = 'N'
  AND d2.d_weekend = 'N'
  AND d2.d_quarter_name = 'Q2'
GROUP BY
    cc2.cc_name,
    d2.d_year,
    d2.d_month_seq,
    inv2.total_qty,
    inv2.cnt_items,
    cc2.cc_closed_date_sk
HAVING COUNT(DISTINCT cc2.cc_call_center_id) > 0
ORDER BY total_qty DESC
OFFSET 0 FETCH NEXT 20 ROWS ONLY

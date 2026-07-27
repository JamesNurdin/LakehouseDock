WITH inv_agg AS (
    SELECT
        inv.inv_date_sk,
        SUM(inv.inv_quantity_on_hand) AS total_qty,
        COUNT(*) AS item_cnt
    FROM inventory inv
    WHERE inv.inv_quantity_on_hand > 500
      AND inv.inv_item_sk IN (101449, 101414)
    GROUP BY inv.inv_date_sk
)
SELECT
    d.d_date,
    cc.cc_name,
    ws.web_name,
    ia.total_qty,
    ia.item_cnt,
    COUNT(DISTINCT cc.cc_call_center_id) AS distinct_cc,
    AVG(cc.cc_gmt_offset) AS avg_cc_gmt_offset
FROM inv_agg ia
JOIN date_dim d
  ON ia.inv_date_sk = d.d_date_sk
JOIN call_center cc
  ON cc.cc_open_date_sk = d.d_date_sk
JOIN web_site ws
  ON ws.web_open_date_sk = d.d_date_sk
WHERE d.d_year = 2001
  AND d.d_month_seq BETWEEN 1200 AND 1210
  AND d.d_day_name = 'Monday'
  AND cc.cc_state = 'CA'
  AND ws.web_state = 'CA'
  AND cc.cc_gmt_offset > -5.0
GROUP BY
    d.d_date,
    cc.cc_name,
    ws.web_name,
    ia.total_qty,
    ia.item_cnt
ORDER BY ia.total_qty DESC
LIMIT 100

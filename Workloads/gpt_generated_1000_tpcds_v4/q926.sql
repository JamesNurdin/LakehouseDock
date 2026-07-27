/*
  Goal: Analyze web return amounts by year, month, state and return reason, while correlating with inventory levels and site information. The query joins all five selected tables, applies multiple realistic filters, uses a CTE subquery, includes a CASE expression, aggregates several measures, orders the results, and limits the output to the top 100 rows.
*/
WITH max_inv AS (
    SELECT inv_date_sk,
           MAX(inv_quantity_on_hand) AS max_qty
    FROM inventory
    WHERE inv_quantity_on_hand > 0
    GROUP BY inv_date_sk
)
SELECT
    d.d_year,
    d.d_month_seq,
    ws.web_state,
    r.r_reason_desc,
    COUNT(*) AS return_cnt,
    SUM(wr.wr_return_amt) AS total_return_amt,
    AVG(i.inv_quantity_on_hand) AS avg_inventory_qty,
    MAX(wr.wr_return_tax) AS max_return_tax,
    SUM(CASE WHEN wr.wr_return_amt > 500 THEN wr.wr_return_amt ELSE 0 END) AS high_return_sum,
    MAX(mi.max_qty) AS max_qty_for_date
FROM date_dim d
INNER JOIN web_returns wr
        ON wr.wr_returned_date_sk = d.d_date_sk
INNER JOIN reason r
        ON wr.wr_reason_sk = r.r_reason_sk
INNER JOIN inventory i
        ON i.inv_date_sk = d.d_date_sk
INNER JOIN web_site ws
        ON ws.web_open_date_sk = d.d_date_sk
LEFT JOIN max_inv mi
        ON mi.inv_date_sk = d.d_date_sk
WHERE d.d_year = 2001
  AND d.d_month_seq BETWEEN 1200 AND 1220
  AND i.inv_quantity_on_hand > 100
  AND i.inv_warehouse_sk IN (8, 12)
  AND wr.wr_return_tax > 10
  AND wr.wr_return_ship_cost > 50
  AND r.r_reason_id = 'AAAAAAAADBAAAAAA'
  AND ws.web_state = 'CA'
GROUP BY d.d_year, d.d_month_seq, ws.web_state, r.r_reason_desc
ORDER BY total_return_amt DESC
LIMIT 100

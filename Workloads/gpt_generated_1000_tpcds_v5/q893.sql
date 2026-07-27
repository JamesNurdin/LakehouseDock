/*
  Goal: Analyze store performance for the year 2001 in California by combining store return metrics with inventory levels, catalog page info, and web site characteristics. The query joins all nine selected tables, applies selective filters, uses a CTE to pre‑aggregate store returns, includes a scalar subquery, performs a LEFT OUTER JOIN on web_returns (with its time dimension), aggregates web return amounts, and orders the result by total store return amount.
*/
WITH store_ret_agg AS (
    SELECT
        sr.sr_store_sk,
        d_ret.d_year,
        COUNT(*)                                   AS cnt_returns,
        SUM(sr.sr_return_amt)                     AS total_return_amt,
        AVG(sr.sr_return_amt)                     AS avg_return_amt
    FROM store_returns sr
    JOIN date_dim d_ret ON sr.sr_returned_date_sk = d_ret.d_date_sk
    GROUP BY sr.sr_store_sk, d_ret.d_year
)
SELECT
    s.s_store_id,
    s.s_state,
    w.w_warehouse_name,
    w.w_warehouse_sq_ft,
    cp.cp_catalog_page_number,
    cp.cp_department,
    ws.web_city,
    d_year.d_year,
    COALESCE(SUM(wr.wr_return_amt), 0)          AS total_web_return_amt,
    COALESCE(SUM(wr.wr_return_quantity), 0)    AS total_web_return_qty,
    agg.cnt_returns,
    agg.total_return_amt,
    agg.avg_return_amt,
    (
        SELECT SUM(inv2.inv_quantity_on_hand)
        FROM inventory inv2
        WHERE inv2.inv_warehouse_sk = w.w_warehouse_sk
          AND inv2.inv_date_sk = d_year.d_date_sk
    )                                            AS inventory_on_hand,
    (
        SELECT COUNT(*)
        FROM inventory inv3
        WHERE inv3.inv_date_sk = d_year.d_date_sk
    )                                            AS inventory_day_count
FROM store_ret_agg agg
JOIN store s ON s.s_store_sk = agg.sr_store_sk
JOIN date_dim d_year ON agg.d_year = d_year.d_year
JOIN inventory inv ON inv.inv_date_sk = d_year.d_date_sk
JOIN warehouse w ON inv.inv_warehouse_sk = w.w_warehouse_sk
JOIN catalog_page cp ON cp.cp_start_date_sk = d_year.d_date_sk
JOIN web_site ws ON ws.web_open_date_sk = d_year.d_date_sk
LEFT JOIN web_returns wr ON wr.wr_returned_date_sk = d_year.d_date_sk
LEFT JOIN time_dim t ON wr.wr_returned_time_sk = t.t_time_sk
WHERE d_year.d_year = 2001
  AND s.s_state = 'CA'
  AND w.w_warehouse_sq_ft > 500000
  AND ws.web_city = 'Pleasant Valley'
  AND cp.cp_department = 'Electronics'
GROUP BY
    s.s_store_id,
    s.s_state,
    w.w_warehouse_name,
    w.w_warehouse_sq_ft,
    cp.cp_catalog_page_number,
    cp.cp_department,
    ws.web_city,
    d_year.d_year,
    agg.cnt_returns,
    agg.total_return_amt,
    agg.avg_return_amt,
    w.w_warehouse_sk,
    d_year.d_date_sk
ORDER BY agg.total_return_amt DESC
LIMIT 100

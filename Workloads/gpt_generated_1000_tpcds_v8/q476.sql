/*
   Goal: Analyse profitability and return loss by year, month and item category, using all selected TPC‑DS tables. The query applies multiple realistic filters, uses a scalar subquery via a CROSS JOIN LATERAL, includes a FULL OUTER JOIN, a UNION of three result sets, a GROUP BY ROLLUP for subtotals and a grand total, a CASE expression to flag profit direction, and a window function to rank categories within each year. Results are ordered and paginated (OFFSET / LIMIT).
*/
WITH unified_data AS (
    /* Web sales part – joins to many dimension tables */
    SELECT
        d.d_year               AS year,
        d.d_month_seq          AS month_seq,
        i.i_category           AS item_category,
        ws.ws_net_profit       AS net_profit,
        0.0                    AS return_loss,
        ws.ws_order_number     AS order_number
    FROM tpcds.web_sales ws
    JOIN tpcds.date_dim d               ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN tpcds.item i                   ON ws.ws_item_sk = i.i_item_sk
    JOIN tpcds.household_demographics hd ON ws.ws_bill_hdemo_sk = hd.hd_demo_sk
    JOIN tpcds.income_band ib          ON hd.hd_income_band_sk = ib.ib_income_band_sk
    JOIN tpcds.call_center cc          ON cc.cc_open_date_sk = d.d_date_sk
    JOIN tpcds.catalog_page cp          ON cp.cp_start_date_sk = d.d_date_sk
    /* LATERAL sub‑query to fetch total inventory for the item on the same date */
    CROSS JOIN LATERAL (
        SELECT SUM(inv.inv_quantity_on_hand) AS total_inventory
        FROM tpcds.inventory inv
        WHERE inv.inv_item_sk = i.i_item_sk
          AND inv.inv_date_sk = d.d_date_sk
    ) inv_lateral
    WHERE i.i_current_price > 100
      AND ib.ib_lower_bound >= 30000
      AND cc.cc_state = 'CA'
      AND cp.cp_type = 'PROMO'
      AND d.d_year = 2001

    UNION ALL

    /* Store returns part – uses a FULL OUTER JOIN to keep unmatched dates */
    SELECT
        d.d_year               AS year,
        d.d_month_seq          AS month_seq,
        i.i_category           AS item_category,
        0.0                    AS net_profit,
        sr.sr_net_loss         AS return_loss,
        sr.sr_ticket_number    AS order_number
    FROM tpcds.store_returns sr
    FULL OUTER JOIN tpcds.date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
    JOIN tpcds.item i               ON sr.sr_item_sk = i.i_item_sk
    JOIN tpcds.reason r             ON sr.sr_reason_sk = r.r_reason_sk
    JOIN tpcds.household_demographics hd ON sr.sr_hdemo_sk = hd.hd_demo_sk
    WHERE r.r_reason_desc LIKE '%damaged%'
      AND i.i_current_price > 100
      AND d.d_year = 2001

    UNION ALL

    /* Web returns part */
    SELECT
        d.d_year               AS year,
        d.d_month_seq          AS month_seq,
        i.i_category           AS item_category,
        0.0                    AS net_profit,
        wr.wr_net_loss         AS return_loss,
        wr.wr_order_number     AS order_number
    FROM tpcds.web_returns wr
    JOIN tpcds.date_dim d               ON wr.wr_returned_date_sk = d.d_date_sk
    JOIN tpcds.item i                   ON wr.wr_item_sk = i.i_item_sk
    JOIN tpcds.reason r                 ON wr.wr_reason_sk = r.r_reason_sk
    JOIN tpcds.household_demographics hd ON wr.wr_refunded_hdemo_sk = hd.hd_demo_sk
    WHERE r.r_reason_desc LIKE '%damaged%'
      AND i.i_current_price > 100
      AND d.d_year = 2001
)
,
aggregated AS (
    SELECT
        year,
        month_seq,
        item_category,
        SUM(net_profit)   AS total_net_profit,
        SUM(return_loss)  AS total_return_loss,
        COUNT(DISTINCT order_number) AS distinct_orders
    FROM unified_data
    GROUP BY ROLLUP (year, month_seq, item_category)
)
SELECT
    year,
    month_seq,
    item_category,
    total_net_profit,
    total_return_loss,
    distinct_orders,
    CASE WHEN total_net_profit > 0 THEN 'Positive' ELSE 'Negative' END AS profit_flag,
    ROW_NUMBER() OVER (PARTITION BY year ORDER BY total_net_profit DESC) AS profit_rank
FROM aggregated
WHERE year IS NOT NULL -- remove the grand‑total row from ordering if desired
ORDER BY year, month_seq, item_category
OFFSET 0 LIMIT 100

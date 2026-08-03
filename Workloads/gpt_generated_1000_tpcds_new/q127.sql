/*
  Goal: Produce a sales‑performance snapshot that combines store sales, web sales and catalog returns, grouped by year, month, store and call‑center, while also showing the ship‑mode used for returns and web orders. The query expands a derived array of state/country values from the call_center table using UNNEST, re‑uses the date_dim and ship_mode tables under multiple aliases, and performs a deep join across all nine selected tables.
*/
WITH cc_expanded AS (
    SELECT
        cc_call_center_sk,
        cc_call_center_id,
        cc_name,
        cc_state,
        cc_country,
        ARRAY[cc_state, cc_country] AS loc_array
    FROM call_center
),
cc_unnested AS (
    SELECT
        cc_call_center_sk,
        cc_call_center_id,
        cc_name,
        loc AS location,
        CASE WHEN loc = cc_state THEN 'state' ELSE 'country' END AS location_type
    FROM cc_expanded
    CROSS JOIN UNNEST(loc_array) AS t(loc)
)
SELECT
    d_sold.d_year,
    d_sold.d_month_seq,
    s.s_store_name,
    cc_unnested.cc_name,
    sm_cr.sm_type          AS return_ship_mode,
    sm_web.sm_type         AS web_ship_mode,
    SUM(ss.ss_ext_sales_price)   AS total_store_sales,
    SUM(ws.ws_ext_sales_price)   AS total_web_sales,
    SUM(cr.cr_return_amount)     AS total_return_amount,
    COUNT(DISTINCT ss.ss_ticket_number) AS store_transactions,
    COUNT(DISTINCT ws.ws_order_number)   AS web_orders
FROM store_sales ss
JOIN date_dim d_sold
  ON ss.ss_sold_date_sk = d_sold.d_date_sk               -- join rule 1
JOIN time_dim t_sold
  ON ss.ss_sold_time_sk = t_sold.t_time_sk               -- join rule 2
JOIN store s
  ON ss.ss_store_sk = s.s_store_sk                       -- join rule 3
JOIN web_sales ws
  ON ws.ws_sold_date_sk = d_sold.d_date_sk               -- join rule 9 (date alias d_sold)
 AND ws.ws_sold_time_sk = t_sold.t_time_sk               -- join rule 9 (time alias t_sold)
JOIN ship_mode sm_web
  ON ws.ws_ship_mode_sk = sm_web.sm_ship_mode_sk          -- join rule 12 (ship_mode alias for web)
JOIN date_dim d_ship
  ON ws.ws_ship_date_sk = d_ship.d_date_sk               -- join rule 11 (ship date)
JOIN catalog_returns cr
  ON cr.cr_returned_date_sk = d_sold.d_date_sk           -- join rule 4 (return date uses same year/month as sales)
 AND cr.cr_returned_time_sk = t_sold.t_time_sk           -- join rule 5 (return time)
JOIN call_center cc
  ON cr.cr_call_center_sk = cc.cc_call_center_sk          -- join rule 6
JOIN ship_mode sm_cr
  ON cr.cr_ship_mode_sk = sm_cr.sm_ship_mode_sk          -- join rule 8 (ship_mode alias for returns)
JOIN catalog_page cp
  ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk        -- join rule 7
JOIN cc_unnested
  ON cc.cc_call_center_sk = cc_unnested.cc_call_center_sk
GROUP BY
    d_sold.d_year,
    d_sold.d_month_seq,
    s.s_store_name,
    cc_unnested.cc_name,
    sm_cr.sm_type,
    sm_web.sm_type
ORDER BY
    d_sold.d_year DESC,
    d_sold.d_month_seq,
    total_store_sales DESC
LIMIT 100

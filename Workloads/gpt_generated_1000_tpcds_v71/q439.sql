/*
Goal: Compare aggregated store‑sales and web‑sales for the year 2001 for items belonging to selected categories and a specific formulation, broken down by store state and item class. The query applies multiple realistic filters, uses an EXISTS semi‑join to keep only stores that were open on a given date, and returns the top 100 rows ordered by total store sales.
*/
WITH store_agg AS (
    SELECT
        d.d_year,
        i.i_category,
        i.i_class,
        s.s_state,
        SUM(ss.ss_ext_sales_price)               AS store_sales_total,
        AVG(ss.ss_net_paid)                       AS store_avg_net_paid,
        COUNT(DISTINCT ss.ss_ticket_number)       AS store_txn_cnt,
        MIN(ss.ss_list_price)                     AS store_min_price,
        MAX(ss.ss_list_price)                     AS store_max_price
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    -- join to capture the store‑closed date for an extra filter
    JOIN date_dim d_closed ON s.s_closed_date_sk = d_closed.d_date_sk
    WHERE d.d_year = 2001                                 -- filter 1: year
      AND i.i_category_id IN (5, 7, 8)                    -- filter 2: category ids
      AND i.i_formulation LIKE '%goldenrod%'             -- filter 3: formulation pattern
      AND s.s_state = 'CA'                               -- filter 4: state
      AND s.s_number_employees > 50                      -- filter 5: employee count
      AND ss.ss_quantity >= 2                           -- filter 6: quantity sold
      AND d_closed.d_year > 1999                         -- filter 7: store closed date after 1999
    GROUP BY d.d_year, i.i_category, i.i_class, s.s_state
),
web_agg AS (
    SELECT
        d2.d_year,
        i2.i_category,
        i2.i_class,
        SUM(ws.ws_ext_sales_price)               AS web_sales_total,
        AVG(ws.ws_net_paid)                       AS web_avg_net_paid,
        COUNT(DISTINCT ws.ws_order_number)       AS web_txn_cnt
    FROM web_sales ws
    JOIN date_dim d2 ON ws.ws_sold_date_sk = d2.d_date_sk
    JOIN item i2 ON ws.ws_item_sk = i2.i_item_sk
    WHERE d2.d_year = 2001                                 -- same year filter as store side
      AND i2.i_category_id IN (5, 7, 8)                    -- same category filter
      AND i2.i_formulation LIKE '%goldenrod%'             -- same formulation filter
      AND ws.ws_quantity >= 2                            -- filter on web quantity
    GROUP BY d2.d_year, i2.i_category, i2.i_class
)
SELECT
    sa.d_year,
    sa.i_category,
    sa.i_class,
    sa.s_state,
    sa.store_sales_total,
    sa.store_avg_net_paid,
    sa.store_txn_cnt,
    sa.store_min_price,
    sa.store_max_price,
    wa.web_sales_total,
    wa.web_avg_net_paid,
    wa.web_txn_cnt
FROM store_agg sa
JOIN web_agg wa
  ON sa.d_year = wa.d_year
 AND sa.i_category = wa.i_category
 AND sa.i_class = wa.i_class
WHERE EXISTS (
    SELECT 1
    FROM store s_check
    JOIN date_dim d_check ON s_check.s_closed_date_sk = d_check.d_date_sk
    WHERE s_check.s_store_sk = (
        SELECT ss_inner.ss_store_sk
        FROM store_sales ss_inner
        WHERE ss_inner.ss_sold_date_sk = (
            SELECT d_inner.d_date_sk
            FROM date_dim d_inner
            WHERE d_inner.d_date = DATE '2001-07-15'
            LIMIT 1
        )
        LIMIT 1
    )
      AND s_check.s_state = 'CA'
)
ORDER BY sa.store_sales_total DESC
LIMIT 100

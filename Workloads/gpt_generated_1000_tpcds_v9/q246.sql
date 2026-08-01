-- Goal: Calculate total net profit and total quantity sold by item category, sold year, and warehouse state,
-- flag whether the rolled‑up profit is positive, count the number of returns per category‑year,
-- and present rollup subtotals ordered by profitability.

WITH cte_sales AS (
    SELECT
        i.i_category,
        d_sold.d_year AS sold_year,
        w.w_state,
        cs.cs_quantity,
        cs.cs_net_profit,
        inv.inv_quantity_on_hand,
        st.s_state,
        cs.cs_net_paid,
        i.i_item_sk
    FROM catalog_sales cs
    JOIN date_dim d_sold
        ON cs.cs_sold_date_sk = d_sold.d_date_sk
    JOIN time_dim td_sold
        ON cs.cs_sold_time_sk = td_sold.t_time_sk
    JOIN date_dim d_ship
        ON cs.cs_ship_date_sk = d_ship.d_date_sk
    JOIN ship_mode sm
        ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN warehouse w
        ON cs.cs_warehouse_sk = w.w_warehouse_sk
    JOIN item i
        ON cs.cs_item_sk = i.i_item_sk
    JOIN inventory inv
        ON inv.inv_item_sk = i.i_item_sk
        AND inv.inv_warehouse_sk = w.w_warehouse_sk
    JOIN date_dim d_inv
        ON inv.inv_date_sk = d_inv.d_date_sk
    JOIN store st
        ON st.s_closed_date_sk = d_inv.d_date_sk
    JOIN web_returns wr
        ON wr.wr_item_sk = i.i_item_sk
        AND wr.wr_returned_date_sk = d_sold.d_date_sk
    WHERE
        d_sold.d_year = 2001                     -- filter 1: sold year
        AND d_ship.d_year = 2001                  -- filter 2: ship year
        AND i.i_category = 'Electronics'         -- filter 3: item category
        AND w.w_gmt_offset BETWEEN -5 AND 5      -- filter 4: warehouse GMT offset
        AND sm.sm_type = 'AIR'                   -- filter 5: ship mode type
        AND cs.cs_quantity > 1                   -- filter 6: minimum quantity
        AND inv.inv_quantity_on_hand > 50        -- filter 7: inventory threshold
        AND st.s_state = 'CA'                    -- filter 8: store state
        AND cs.cs_net_paid > 0                   -- filter 9: positive net paid
)
SELECT
    si.i_category,
    si.sold_year,
    si.w_state,
    SUM(si.cs_net_profit) AS total_net_profit,
    SUM(si.cs_quantity)   AS total_quantity,
    CASE WHEN SUM(si.cs_net_profit) > 0 THEN 'Profit' ELSE 'Loss' END AS profit_flag,
    (
        SELECT COUNT(*)
        FROM web_returns wr2
        JOIN date_dim d2
            ON wr2.wr_returned_date_sk = d2.d_date_sk
        JOIN item i2
            ON wr2.wr_item_sk = i2.i_item_sk
        WHERE d2.d_year = si.sold_year
          AND i2.i_category = si.i_category
    ) AS returns_cnt
FROM cte_sales si
GROUP BY ROLLUP(si.i_category, si.sold_year, si.w_state)
HAVING SUM(si.cs_net_profit) > 1000
ORDER BY profit_flag DESC, total_net_profit DESC
LIMIT 100

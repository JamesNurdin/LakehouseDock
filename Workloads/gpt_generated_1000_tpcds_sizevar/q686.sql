-- Goal: Summarize web sales net revenue and catalog return amounts by customer state, ship mode type, and hour of day,
-- providing subtotals and a grand total (ROLLUP), ranking states by total net paid, and limiting to the top 100 rows.
-- The query joins all seven selected tables using only the permitted join keys, applies many realistic filter predicates,
-- compares a column to a scalar subquery, uses a CTE, includes a DISTINCT UNION, and adds a ranking window function.
WITH base_data AS (
    SELECT
        ws.ws_order_number,
        ws.ws_net_paid,
        ws.ws_ext_tax,
        ws.ws_ext_discount_amt,
        ws.ws_sold_date_sk,
        ca.ca_state,
        ca.ca_city,
        sm.sm_type,
        sm.sm_ship_mode_id,
        td.t_hour,
        wsit.web_country,
        cr.cr_return_amount,
        cr.cr_return_tax,
        wr.wr_return_amt,
        wr.wr_return_tax
    FROM web_sales ws
    JOIN time_dim td
        ON ws.ws_sold_time_sk = td.t_time_sk
    JOIN ship_mode sm
        ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN web_site wsit
        ON ws.ws_web_site_sk = wsit.web_site_sk
    JOIN customer_address ca
        ON ws.ws_bill_addr_sk = ca.ca_address_sk
    JOIN web_returns wr
        ON wr.wr_item_sk = ws.ws_item_sk
       AND wr.wr_order_number = ws.ws_order_number
    JOIN catalog_returns cr
        ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
       AND cr.cr_returned_time_sk = td.t_time_sk
    WHERE ws.ws_sold_date_sk BETWEEN 2451500 AND 2451600                     -- date surrogate range
      AND ws.ws_ext_tax > 15.00                                            -- realistic tax filter
      AND ca.ca_state = 'CA'                                               -- state filter
      AND sm.sm_type = 'AIR'                                               -- ship mode type filter
      AND td.t_hour BETWEEN 8 AND 17                                      -- business hours
      AND wsit.web_country = 'United States'                               -- site country filter
      AND cr.cr_return_tax < 20.00                                         -- return tax ceiling
      AND ws.ws_ext_tax > (
            SELECT MAX(cr_return_tax)
            FROM catalog_returns
            WHERE cr_return_tax IS NOT NULL
        )                                                               -- scalar subquery comparison
)
SELECT
    ca_state,
    sm_type,
    t_hour,
    total_net_paid,
    avg_return_amount,
    distinct_orders,
    ROW_NUMBER() OVER (PARTITION BY ca_state ORDER BY total_net_paid DESC) AS state_rank
FROM (
    SELECT
        ca_state,
        sm_type,
        t_hour,
        SUM(ws_net_paid) AS total_net_paid,
        AVG(cr_return_amount) AS avg_return_amount,
        COUNT(DISTINCT ws_order_number) AS distinct_orders
    FROM base_data
    GROUP BY ROLLUP (ca_state, sm_type, t_hour)
    UNION DISTINCT
    SELECT
        ca_state,
        sm_type,
        t_hour,
        SUM(ws_net_paid) AS total_net_paid,
        AVG(cr_return_amount) AS avg_return_amount,
        COUNT(DISTINCT ws_order_number) AS distinct_orders
    FROM base_data
    WHERE sm_type = 'AIR' AND ca_state = 'CA' AND t_hour = 10
    GROUP BY ROLLUP (ca_state, sm_type, t_hour)
) AS agg
ORDER BY ca_state, sm_type, t_hour
LIMIT 100

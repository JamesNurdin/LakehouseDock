/*
Goal: Analyze net financial performance per state and household buy‑potential segment by combining sales and returns data, applying multiple filters, using grouping sets, window ranking, scalar sub‑queries, IN/EXISTS predicates, and a UNION ALL set operation.
*/
WITH sales_pre AS (
    SELECT
        ca.ca_state,
        hd.hd_buy_potential,
        td.t_meal_time,
        ss.ss_net_paid,
        ss.ss_net_profit,
        ss.ss_sales_price,
        ss.ss_quantity,
        td.t_hour
    FROM store_sales ss
    JOIN time_dim td ON ss.ss_sold_time_sk = td.t_time_sk
    JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
    JOIN customer_address ca ON ss.ss_addr_sk = ca.ca_address_sk
    WHERE td.t_meal_time = 'dinner'
      AND td.t_hour BETWEEN 12 AND 18
      AND ca.ca_state = 'CA'
      AND hd.hd_buy_potential = '>10000'
      AND ss.ss_sales_price > 100
),
returns_pre AS (
    SELECT
        ca.ca_state,
        hd.hd_buy_potential,
        td.t_meal_time,
        cr.cr_return_amount,
        cr.cr_return_quantity,
        cr.cr_net_loss,
        td.t_hour
    FROM catalog_returns cr
    JOIN time_dim td ON cr.cr_returned_time_sk = td.t_time_sk
    JOIN household_demographics hd ON cr.cr_refunded_hdemo_sk = hd.hd_demo_sk
    JOIN customer_address ca ON cr.cr_refunded_addr_sk = ca.ca_address_sk
    WHERE td.t_meal_time = 'dinner'
      AND td.t_hour BETWEEN 12 AND 18
      AND ca.ca_state = 'CA'
      AND hd.hd_buy_potential = '>10000'
      AND cr.cr_return_quantity > 0
),
union_data AS (
    SELECT
        ca_state          AS state,
        hd_buy_potential,
        ss_net_paid       AS amount,
        ss_net_profit     AS profit,
        ss_sales_price    AS price,
        ss_quantity       AS qty,
        'sale'            AS src
    FROM sales_pre
    UNION ALL
    SELECT
        ca_state          AS state,
        hd_buy_potential,
        -cr_return_amount AS amount,
        -cr_net_loss      AS profit,
        NULL              AS price,
        cr_return_quantity AS qty,
        'return'          AS src
    FROM returns_pre
),
agg AS (
    SELECT
        state,
        hd_buy_potential,
        SUM(amount) AS total_amount,
        SUM(profit) AS total_profit,
        SUM(qty)    AS total_qty,
        COUNT(*)    AS rows_cnt
    FROM union_data
    GROUP BY GROUPING SETS ((state, hd_buy_potential), (state))
    HAVING SUM(amount) > 0
),
filtered AS (
    SELECT *
    FROM agg
    WHERE total_amount > 5000
      AND total_qty    >= 20
      AND rows_cnt     >= 5
      AND state IN (SELECT ca_state FROM customer_address WHERE ca_city = 'Washington')
      AND EXISTS (
          SELECT 1 FROM time_dim td2
          WHERE td2.t_meal_time = 'dinner' AND td2.t_hour BETWEEN 12 AND 18
      )
)
SELECT
    state,
    hd_buy_potential,
    total_amount,
    total_profit,
    total_qty,
    rows_cnt,
    /* Adjust profit by subtracting total return amount for the same state */
    total_profit - COALESCE(
        (SELECT SUM(cr.cr_return_amount)
         FROM catalog_returns cr
         JOIN customer_address ca ON cr.cr_refunded_addr_sk = ca.ca_address_sk
         WHERE ca.ca_state = filtered.state),
        0) AS adjusted_profit,
    RANK() OVER (ORDER BY total_profit DESC) AS profit_rank,
    ROW_NUMBER() OVER (PARTITION BY state ORDER BY total_amount DESC) AS rn_state
FROM filtered
ORDER BY profit_rank
LIMIT 100

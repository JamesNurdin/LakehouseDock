/* goal: Summarize 2022 store return performance by state and return‑amount level, compare the average summed returns to the total 2022 returns, and keep only states that have a positive GMT offset or are Florida. */
WITH base AS (
    SELECT
        ca.ca_state,
        ca.ca_city,
        d.d_year,
        sr.sr_return_amt,
        sr.sr_fee,
        sr.sr_net_loss,
        p.p_channel_dmail,
        p.p_channel_tv,
        inv.inv_quantity_on_hand,
        r.r_reason_desc,
        CASE
            WHEN sr.sr_return_amt > 200 THEN 'HIGH'
            WHEN sr.sr_return_amt > 100 THEN 'MEDIUM'
            ELSE 'LOW'
        END AS return_level
    FROM store_returns sr
    JOIN date_dim d
        ON sr.sr_returned_date_sk = d.d_date_sk
    JOIN customer_address ca
        ON sr.sr_addr_sk = ca.ca_address_sk
    JOIN reason r
        ON sr.sr_reason_sk = r.r_reason_sk
    JOIN inventory inv
        ON inv.inv_date_sk = d.d_date_sk
    JOIN promotion p
        ON p.p_start_date_sk = d.d_date_sk
    WHERE d.d_year = 2022
      AND sr.sr_return_amt > 100
      AND ca.ca_state IN ('CA','TX','NY')
),
per_state AS (
    SELECT
        state,
        return_level,
        SUM(sr_return_amt)               AS sum_return_amt,
        AVG(inv_quantity_on_hand)        AS avg_qty_on_hand,
        COUNT(DISTINCT city)             AS distinct_cities
    FROM (
        SELECT
            ca_state  AS state,
            ca_city   AS city,
            return_level,
            sr_return_amt,
            inv_quantity_on_hand
        FROM base
    ) t
    GROUP BY state, return_level
),
filtered_state AS (
    SELECT
        state,
        AVG(sum_return_amt) AS avg_sum_return
    FROM per_state
    GROUP BY state
    HAVING AVG(sum_return_amt) > 500
),
total_2022 AS (
    SELECT
        SUM(sr.sr_return_amt) AS total_return_2022
    FROM store_returns sr
    JOIN date_dim d
        ON sr.sr_returned_date_sk = d.d_date_sk
    WHERE d.d_year = 2022
),
relevant_states AS (
    SELECT DISTINCT ca_state FROM customer_address WHERE ca_gmt_offset > 0
    UNION
    SELECT DISTINCT ca_state FROM customer_address WHERE ca_state = 'FL'
)
SELECT
    fs.state,
    fs.avg_sum_return,
    t2022.total_return_2022,
    CASE
        WHEN fs.avg_sum_return > t2022.total_return_2022 * 0.1 THEN 'SIGNIFICANT'
        ELSE 'MODERATE'
    END AS significance
FROM filtered_state fs
CROSS JOIN total_2022 t2022
JOIN relevant_states rs
    ON fs.state = rs.ca_state
ORDER BY fs.avg_sum_return DESC
LIMIT 100

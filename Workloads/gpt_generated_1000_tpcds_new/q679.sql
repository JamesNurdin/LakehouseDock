WITH sales_details AS (
    SELECT
        ss.ss_ticket_number AS ticket_number,
        ss.ss_quantity,
        ss.ss_net_paid,
        dd.d_year,
        ca.ca_state,
        ca.ca_city,
        ca.ca_gmt_offset
    FROM store_sales ss
    JOIN date_dim dd ON ss.ss_sold_date_sk = dd.d_date_sk
    JOIN customer_address ca ON ss.ss_addr_sk = ca.ca_address_sk
),
returns_details AS (
    SELECT
        sr.sr_ticket_number AS ticket_number,
        sr.sr_return_quantity,
        sr.sr_return_amt,
        dd.d_year AS return_year,
        ca.ca_state AS return_state,
        ca.ca_city AS return_city,
        ca.ca_gmt_offset AS return_gmt_offset
    FROM store_returns sr
    JOIN date_dim dd ON sr.sr_returned_date_sk = dd.d_date_sk
    JOIN customer_address ca ON sr.sr_addr_sk = ca.ca_address_sk
),
sales_only_tickets AS (
    SELECT ticket_number FROM sales_details
    EXCEPT
    SELECT ticket_number FROM returns_details
),
full_join AS (
    SELECT
        COALESCE(s.ticket_number, r.ticket_number) AS ticket_number,
        s.ss_quantity,
        s.ss_net_paid,
        r.sr_return_quantity,
        r.sr_return_amt,
        COALESCE(s.d_year, r.return_year) AS year,
        COALESCE(s.ca_state, r.return_state) AS state,
        COALESCE(s.ca_city, r.return_city) AS city,
        COALESCE(s.ca_gmt_offset, r.return_gmt_offset) AS gmt_offset
    FROM sales_details s
    FULL OUTER JOIN returns_details r
        ON s.ticket_number = r.ticket_number
),
filtered AS (
    SELECT *
    FROM full_join
    WHERE year BETWEEN 1998 AND 2002                     -- predicate 1
      AND state IN ('CA', 'TX', 'NY')                     -- predicate 2
      AND gmt_offset >= -8.00                            -- predicate 3
      AND (ss_quantity IS NOT NULL AND ss_quantity > 0)  -- predicate 4
      AND (sr_return_quantity IS NULL OR sr_return_quantity < 5) -- predicate 5
),
unnested AS (
    SELECT
        ticket_number,
        year,
        state,
        city,
        gmt_offset,
        ss_quantity,
        sr_return_quantity,
        ss_net_paid,
        sr_return_amt,
        array_element AS city_state
    FROM filtered
    CROSS JOIN LATERAL (
        SELECT ARRAY[state, city] AS state_city_arr
    ) arr
    CROSS JOIN UNNEST(arr.state_city_arr) AS t(array_element)
),
aggregated AS (
    SELECT
        state,
        year,
        SUM(ss_net_paid) AS total_net_paid,
        SUM(COALESCE(sr_return_amt, 0)) AS total_return_amt,
        COUNT(DISTINCT ticket_number) AS ticket_cnt,
        GROUPING(state) AS g_state,
        GROUPING(year) AS g_year
    FROM unnested
    GROUP BY GROUPING SETS ((state, year), (state), (year))
    HAVING state IS NOT NULL AND year IS NOT NULL
),
-- rows that have sales but no corresponding return
ticket_counts AS (
    SELECT
        sd.ca_state AS state,
        sd.d_year AS year,
        COUNT(*) AS tickets_without_return
    FROM sales_details sd
    WHERE sd.ticket_number IN (SELECT ticket_number FROM sales_only_tickets)
    GROUP BY sd.ca_state, sd.d_year
)
SELECT
    ag.state,
    ag.year,
    ag.total_net_paid,
    ag.total_return_amt,
    ag.ticket_cnt,
    COALESCE(tc.tickets_without_return, 0) AS tickets_without_return,
    ROW_NUMBER() OVER (PARTITION BY ag.state ORDER BY ag.year DESC) AS rn_state_year
FROM aggregated ag
LEFT JOIN ticket_counts tc
    ON ag.state = tc.state AND ag.year = tc.year
ORDER BY ag.state NULLS LAST, ag.year NULLS LAST

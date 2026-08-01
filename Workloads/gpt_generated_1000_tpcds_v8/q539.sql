WITH
    -- Sample a fraction of the web_sales fact table
    ws_sample AS (
        SELECT *
        FROM web_sales TABLESAMPLE BERNOULLI (5)
    ),
    -- Join web_sales to all its allowed dimensions (six joins)
    ws_joined AS (
        SELECT
            ws.ws_order_number,
            ws.ws_ext_sales_price,
            ws.ws_quantity,
            d_sold.d_year          AS sold_year,
            d_ship.d_year          AS ship_year,
            hd_bill.hd_income_band_sk AS bill_income_band,
            hd_ship.hd_income_band_sk AS ship_income_band,
            ca_bill.ca_state      AS bill_state,
            ca_ship.ca_state      AS ship_state
        FROM ws_sample ws
        JOIN date_dim d_sold   ON ws.ws_sold_date_sk = d_sold.d_date_sk
        JOIN date_dim d_ship   ON ws.ws_ship_date_sk = d_ship.d_date_sk
        JOIN household_demographics hd_bill ON ws.ws_bill_hdemo_sk = hd_bill.hd_demo_sk
        JOIN household_demographics hd_ship ON ws.ws_ship_hdemo_sk = hd_ship.hd_demo_sk
        JOIN customer_address ca_bill       ON ws.ws_bill_addr_sk = ca_bill.ca_address_sk
        JOIN customer_address ca_ship       ON ws.ws_ship_addr_sk = ca_ship.ca_address_sk
    ),
    -- Store returns and its allowed dimensions (five joins)
    sr_joined AS (
        SELECT
            sr.sr_ticket_number,
            sr.sr_return_amt,
            sr.sr_return_quantity,
            d_ret.d_year               AS return_year,
            hd_ret.hd_income_band_sk   AS ret_income_band,
            ca_ret.ca_state            AS ret_state,
            sr.sr_store_sk,
            sr.sr_hdemo_sk,
            sr.sr_addr_sk
        FROM store_returns sr
        JOIN date_dim d_ret           ON sr.sr_returned_date_sk = d_ret.d_date_sk
        JOIN household_demographics hd_ret ON sr.sr_hdemo_sk = hd_ret.hd_demo_sk
        JOIN customer_address ca_ret       ON sr.sr_addr_sk = ca_ret.ca_address_sk
    ),
    -- Bring the store dimension (single join)
    sr_with_store AS (
        SELECT
            sr.*,
            s.s_store_id,
            s.s_state,
            s.s_floor_space
        FROM sr_joined sr
        JOIN store s ON sr.sr_store_sk = s.s_store_sk
    ),
    -- LATERAL subquery producing an adjusted return amount per row
    sr_lateral AS (
        SELECT
            srws.*, 
            la.adj_return_amt
        FROM sr_with_store srws
        CROSS JOIN LATERAL (
            SELECT srws.sr_return_amt * 0.05 AS adj_return_amt
        ) la
    ),
    -- Aggregate returns per store (includes a window function and a scalar subquery)
    returns_agg AS (
        SELECT
            s_store_id,
            s_state,
            s_floor_space,
            SUM(sr_lateral.sr_return_amt)       AS total_return_amt,
            SUM(sr_lateral.adj_return_amt)      AS total_adj_return_amt,
            COUNT(DISTINCT sr_lateral.sr_ticket_number) AS distinct_return_tickets,
            ROW_NUMBER() OVER (PARTITION BY s_state ORDER BY SUM(sr_lateral.sr_return_amt) DESC) AS state_rank,
            (SELECT AVG(ws_ext_sales_price) FROM ws_sample) AS avg_global_sales
        FROM sr_lateral
        GROUP BY s_store_id, s_state, s_floor_space
        HAVING SUM(sr_lateral.sr_return_amt) > 5000
    ),
    -- Call center info (two joins, filtered to CA)
    cc_info AS (
        SELECT
            cc.cc_call_center_id,
            cc.cc_state,
            d_open.d_year AS open_year,
            d_close.d_year AS close_year,
            cc.cc_name
        FROM call_center cc
        JOIN date_dim d_open  ON cc.cc_open_date_sk  = d_open.d_date_sk
        JOIN date_dim d_close ON cc.cc_closed_date_sk = d_close.d_date_sk
        WHERE cc.cc_state = 'CA'
    )
-- First sub‑select: stores from returns that are in California
SELECT DISTINCT
    ra.s_store_id,
    ra.total_return_amt,
    ra.state_rank
FROM returns_agg ra
WHERE ra.s_state = 'CA'
INTERSECT
-- Second sub‑select: stores that have a large floor space (no return data needed)
SELECT DISTINCT
    s.s_store_id,
    0 AS total_return_amt,
    0 AS state_rank
FROM store s
WHERE s.s_floor_space > 30000
EXCEPT
-- Third sub‑select: exclude stores whose city starts with 'A'
SELECT DISTINCT
    s2.s_store_id,
    0,
    0
FROM store s2
WHERE s2.s_city LIKE 'A%'
ORDER BY total_return_amt DESC
LIMIT 100

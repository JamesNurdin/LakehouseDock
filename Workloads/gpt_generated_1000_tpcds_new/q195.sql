WITH
    -- Base tables (no projection, just to keep query readable)
    sr AS (SELECT * FROM store_returns),
    ws AS (SELECT * FROM web_sales)
SELECT
    s_a.s_division_id,
    s_a.s_market_desc,
    s_b.s_store_name AS additional_store_name,
    ca_ret2.ca_state AS return_address_state,
    sm.sm_type,
    r_a.r_reason_desc,
    ca_ship.ca_city AS ship_city,
    ship_ret_counts.ship_return_cnt,
    SUM(ws.ws_ext_sales_price) AS total_web_sales,
    SUM(sr.sr_net_loss) AS total_store_return_loss
FROM sr
    -- Join store_returns to a shared customer address (billing address for web_sales)
    INNER JOIN customer_address ca_shared
        ON sr.sr_addr_sk = ca_shared.ca_address_sk
    -- Additional inner joins from store_returns
    INNER JOIN store s_a
        ON sr.sr_store_sk = s_a.s_store_sk
    INNER JOIN reason r_a
        ON sr.sr_reason_sk = r_a.r_reason_sk
    -- Extra alias joins to increase join count
    INNER JOIN store s_b
        ON sr.sr_store_sk = s_b.s_store_sk
    INNER JOIN customer_address ca_ret2
        ON sr.sr_addr_sk = ca_ret2.ca_address_sk
    -- Full outer join to reason (different alias) keeping unmatched rows on both sides
    FULL OUTER JOIN reason r_full
        ON sr.sr_reason_sk = r_full.r_reason_sk
    -- Join web_sales to the same shared address (billing address)
    INNER JOIN ws
        ON ws.ws_bill_addr_sk = ca_shared.ca_address_sk
    -- Join web_sales to its shipping address (second alias of customer_address)
    INNER JOIN customer_address ca_ship
        ON ws.ws_ship_addr_sk = ca_ship.ca_address_sk
    -- Join web_sales to ship mode
    INNER JOIN ship_mode sm
        ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
    -- LATERAL subquery counting how many store returns originated from the shipping address
    LEFT JOIN LATERAL (
        SELECT COUNT(*) AS ship_return_cnt
        FROM store_returns sr2
        WHERE sr2.sr_addr_sk = ca_ship.ca_address_sk
    ) AS ship_ret_counts ON TRUE
GROUP BY
    s_a.s_division_id,
    s_a.s_market_desc,
    s_b.s_store_name,
    ca_ret2.ca_state,
    sm.sm_type,
    r_a.r_reason_desc,
    ca_ship.ca_city,
    ship_ret_counts.ship_return_cnt
ORDER BY
    total_web_sales DESC
LIMIT 100

WITH
    -- scalar sub‑query returning a single value (average catalog return amount)
    avg_cr_amount AS (
        SELECT AVG(cr_return_amount) AS avg_amt
        FROM catalog_returns
    ),

    -- total return amount per reason from store returns (filtering on a minimum amount)
    store_reason AS (
        SELECT r.r_reason_desc AS description,
               SUM(sr.sr_return_amt) AS total_return_amount
        FROM store_returns sr
        JOIN reason r
          ON sr.sr_reason_sk = r.r_reason_sk
        WHERE sr.sr_return_amt > 50
        GROUP BY r.r_reason_desc
    ),

    -- total return amount per reason from catalog returns (compared to the scalar sub‑query)
    catalog_reason AS (
        SELECT r.r_reason_desc AS description,
               SUM(cr.cr_return_amount) AS total_return_amount
        FROM catalog_returns cr
        JOIN reason r
          ON cr.cr_reason_sk = r.r_reason_sk
        WHERE cr.cr_return_amount > (SELECT avg_amt FROM avg_cr_amount)
        GROUP BY r.r_reason_desc
    ),

    -- profit (net paid) per ship mode, retaining every ship mode even when no sales exist
    ship_mode_profit AS (
        SELECT sm.sm_type AS description,
               SUM(COALESCE(ws.ws_net_paid, 0)) AS total_return_amount
        FROM web_sales ws
        RIGHT OUTER JOIN ship_mode sm
          ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
        GROUP BY sm.sm_type
    )
SELECT DISTINCT description,
                total_return_amount
FROM (
        SELECT description, total_return_amount FROM store_reason
        UNION ALL
        SELECT description, total_return_amount FROM catalog_reason
        UNION ALL
        SELECT description, total_return_amount FROM ship_mode_profit
) combined
ORDER BY total_return_amount DESC

WITH store_return_summary AS (
    SELECT
        s.s_state AS state,
        'STORE' AS return_type,
        SUM(sr.sr_return_amt) AS total_return_amt,
        SUM(sr.sr_return_tax) AS total_return_tax,
        SUM(sr.sr_net_loss) AS total_net_loss
    FROM store_returns sr
    JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
    JOIN store s ON sr.sr_store_sk = s.s_store_sk
    WHERE d.d_year = 2001
      AND s.s_tax_percentage > (
          SELECT AVG(cc_tax_percentage)
          FROM call_center
          WHERE cc_division = 2
      )
    GROUP BY ROLLUP (s.s_state)
),
web_return_summary AS (
    SELECT
        ca.ca_state AS state,
        'WEB' AS return_type,
        SUM(wr.wr_return_amt) AS total_return_amt,
        SUM(wr.wr_return_tax) AS total_return_tax,
        SUM(wr.wr_net_loss) AS total_net_loss
    FROM web_returns wr
    JOIN date_dim d ON wr.wr_returned_date_sk = d.d_date_sk
    JOIN customer_address ca ON wr.wr_returning_addr_sk = ca.ca_address_sk
    WHERE d.d_year = 2001
      AND EXISTS (
          SELECT 1
          FROM web_sales ws
          JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
          JOIN date_dim d2 ON p.p_start_date_sk = d2.d_date_sk
          WHERE ws.ws_order_number = wr.wr_order_number
            AND d2.d_year = 2001
      )
    GROUP BY CUBE (ca.ca_state)
)
SELECT
    state,
    return_type,
    total_return_amt,
    total_return_tax,
    total_net_loss
FROM store_return_summary
UNION ALL
SELECT
    state,
    return_type,
    total_return_amt,
    total_return_tax,
    total_net_loss
FROM web_return_summary
ORDER BY state NULLS FIRST, return_type
LIMIT 100

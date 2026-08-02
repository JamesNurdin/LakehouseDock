WITH agg AS (
    SELECT
        d_ret.d_year,
        ws.web_city,
        ca_refunded.ca_state,
        COUNT(*) AS returns_cnt,
        SUM(wr.wr_return_amt) AS total_return_amt,
        AVG(i.inv_quantity_on_hand) AS avg_inventory_qty,
        MIN(wr.wr_return_amt) AS min_return_amt,
        MAX(wr.wr_return_amt) AS max_return_amt,
        SUM(CASE WHEN ca_refunded.ca_location_type = 'condo' THEN 1 ELSE 0 END) AS condo_return_cnt,
        SUM(CASE WHEN i.inv_quantity_on_hand > 200 THEN 1 ELSE 0 END) AS high_stock_return_cnt
    FROM web_returns wr
    JOIN date_dim d_ret
        ON wr.wr_returned_date_sk = d_ret.d_date_sk
    JOIN customer c_refunded
        ON wr.wr_refunded_customer_sk = c_refunded.c_customer_sk
    JOIN customer_address ca_refunded
        ON wr.wr_refunded_addr_sk = ca_refunded.ca_address_sk
    LEFT JOIN inventory i
        ON i.inv_date_sk = d_ret.d_date_sk
    LEFT JOIN web_site ws
        ON ws.web_open_date_sk = d_ret.d_date_sk
    WHERE d_ret.d_year = 2001
      AND ca_refunded.ca_state = 'UT'
      AND ca_refunded.ca_location_type = 'condo'
      AND ws.web_city = 'Pleasant Hill'
      AND i.inv_quantity_on_hand >= 100
      AND wr.wr_return_amt > 50
      AND EXISTS (
          SELECT 1
          FROM store s
          WHERE s.s_closed_date_sk = d_ret.d_date_sk
            AND s.s_state = 'CA'
      )
    GROUP BY ROLLUP (d_ret.d_year, ws.web_city, ca_refunded.ca_state)
)
SELECT
    d_year,
    web_city,
    ca_state,
    returns_cnt,
    total_return_amt,
    avg_inventory_qty,
    min_return_amt,
    max_return_amt,
    condo_return_cnt,
    high_stock_return_cnt,
    SUM(total_return_amt) OVER (
        ORDER BY d_year, web_city, ca_state
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    ) AS cumulative_return_amt,
    CASE
        WHEN total_return_amt > 1000 THEN 'High'
        ELSE 'Low'
    END AS return_category
FROM agg
ORDER BY d_year, web_city, ca_state
LIMIT 100

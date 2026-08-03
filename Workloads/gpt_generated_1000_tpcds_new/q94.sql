-- Goal: Analyze profitability and return behavior for air‑shipped orders in 2002, broken down by return reason. The query first aggregates sales, profit and return amounts per year, reason and ship mode, then computes average sales and total profit per reason, keeping only reasons whose profit exceeds the overall average profit.
WITH base AS (
    SELECT
        d.d_year,
        r1.r_reason_desc,
        sm.sm_type,
        SUM(ws.ws_ext_sales_price)          AS total_sales,
        SUM(ws.ws_net_profit)              AS total_profit,
        SUM(cr.cr_return_amount)           AS total_catalog_return,
        SUM(wr.wr_return_amt)              AS total_web_return
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN customer_demographics cd ON ws.ws_bill_cdemo_sk = cd.cd_demo_sk
    JOIN customer_address ca ON ws.ws_bill_addr_sk = ca.ca_address_sk
    JOIN ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
    LEFT JOIN web_returns wr ON ws.ws_order_number = wr.wr_order_number
    LEFT JOIN reason r1 ON wr.wr_reason_sk = r1.r_reason_sk
    LEFT JOIN catalog_returns cr ON cr.cr_returned_date_sk = d.d_date_sk
    LEFT JOIN reason r2 ON cr.cr_reason_sk = r2.r_reason_sk
    WHERE d.d_year = 2002                         -- filter 1: specific fiscal year
      AND ws.ws_list_price > 100                  -- filter 2: higher‑priced items
      AND sm.sm_type = 'AIR'                      -- filter 3: air shipping
    GROUP BY d.d_year, r1.r_reason_desc, sm.sm_type
)
SELECT
    b.r_reason_desc,
    AVG(b.total_sales)            AS avg_sales,
    SUM(b.total_profit)           AS sum_profit,
    SUM(b.total_catalog_return)  AS sum_catalog_return,
    SUM(b.total_web_return)       AS sum_web_return
FROM base b
GROUP BY b.r_reason_desc
HAVING SUM(b.total_profit) > (
    SELECT avg(ws_net_profit) FROM web_sales
)                                            -- scalar subquery comparison
ORDER BY avg_sales DESC
LIMIT 100

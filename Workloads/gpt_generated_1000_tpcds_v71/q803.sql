-- Goal: Summarize web sales by call‑center and year, showing totals, counts and a discount category,
-- include subtotal rows via ROLLUP, rank call‑centers by net paid, and limit to the top 100 rows.

WITH sales_agg AS (
    SELECT
        cc.cc_name,
        d_sold.d_year,
        SUM(ws.ws_net_paid)                         AS total_net_paid,
        COUNT(*)                                    AS num_orders,
        AVG(ws.ws_ext_discount_amt)                AS avg_discount,
        CASE WHEN SUM(ws.ws_ext_discount_amt) > 1000 THEN 'High' ELSE 'Low' END AS discount_category
    FROM web_sales ws
    JOIN date_dim d_sold
        ON ws.ws_sold_date_sk = d_sold.d_date_sk
    JOIN call_center cc
        ON cc.cc_open_date_sk = d_sold.d_date_sk
    WHERE d_sold.d_year = 2001                              -- filter 1: specific year
      AND cc.cc_tax_percentage > 0.05                      -- filter 2: tax percentage threshold
      AND ws.ws_ext_discount_amt > 500                     -- filter 3: minimum discount amount
    GROUP BY ROLLUP (cc.cc_name, d_sold.d_year)
)
SELECT
    cc_name,
    d_year,
    total_net_paid,
    num_orders,
    avg_discount,
    discount_category,
    ROW_NUMBER() OVER (PARTITION BY cc_name ORDER BY total_net_paid DESC) AS rank_within_cc
FROM sales_agg
ORDER BY total_net_paid DESC
LIMIT 100

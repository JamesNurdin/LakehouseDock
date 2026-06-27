WITH catalog_sales_agg AS (
    SELECT
        d.d_year,
        d.d_month_seq,
        sm.sm_type AS ship_mode_type,
        SUM(cs.cs_net_profit) AS total_net_profit,
        SUM(cs.cs_ext_sales_price) AS total_sales
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    WHERE d.d_date >= DATE '2000-01-01' AND d.d_date < DATE '2001-01-01'
    GROUP BY d.d_year, d.d_month_seq, sm.sm_type
),
web_sales_agg AS (
    SELECT
        d.d_year,
        d.d_month_seq,
        sm.sm_type AS ship_mode_type,
        SUM(ws.ws_net_profit) AS total_net_profit,
        SUM(ws.ws_ext_sales_price) AS total_sales
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
    WHERE d.d_date >= DATE '2000-01-01' AND d.d_date < DATE '2001-01-01'
    GROUP BY d.d_year, d.d_month_seq, sm.sm_type
)
SELECT
    COALESCE(ca.d_year, wa.d_year) AS year,
    COALESCE(ca.d_month_seq, wa.d_month_seq) AS month_seq,
    COALESCE(ca.ship_mode_type, wa.ship_mode_type) AS ship_mode_type,
    COALESCE(ca.total_net_profit, 0) + COALESCE(wa.total_net_profit, 0) AS total_net_profit,
    COALESCE(ca.total_sales, 0) + COALESCE(wa.total_sales, 0) AS total_sales
FROM catalog_sales_agg ca
FULL OUTER JOIN web_sales_agg wa
    ON ca.d_year = wa.d_year
   AND ca.d_month_seq = wa.d_month_seq
   AND ca.ship_mode_type = wa.ship_mode_type
ORDER BY year, month_seq, ship_mode_type

WITH store_sales_agg AS (
    SELECT d.d_year,
           d.d_month_seq AS month_seq,
           ca.ca_state AS state,
           SUM(ss.ss_net_paid_inc_tax) AS net_sales,
           SUM(ss.ss_net_profit) AS net_profit
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN customer_address ca ON ss.ss_addr_sk = ca.ca_address_sk
    GROUP BY d.d_year, d.d_month_seq, ca.ca_state
),
web_sales_agg AS (
    SELECT d.d_year,
           d.d_month_seq AS month_seq,
           ca.ca_state AS state,
           SUM(ws.ws_net_paid_inc_tax) AS net_sales,
           SUM(ws.ws_net_profit) AS net_profit
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN customer_address ca ON ws.ws_ship_addr_sk = ca.ca_address_sk
    GROUP BY d.d_year, d.d_month_seq, ca.ca_state
),
catalog_sales_agg AS (
    SELECT d.d_year,
           d.d_month_seq AS month_seq,
           ca.ca_state AS state,
           SUM(cs.cs_net_paid_inc_tax) AS net_sales,
           SUM(cs.cs_net_profit) AS net_profit
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN customer_address ca ON cs.cs_ship_addr_sk = ca.ca_address_sk
    GROUP BY d.d_year, d.d_month_seq, ca.ca_state
),
store_returns_agg AS (
    SELECT d.d_year,
           d.d_month_seq AS month_seq,
           ca.ca_state AS state,
           SUM(sr.sr_net_loss) AS return_loss
    FROM store_returns sr
    JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
    JOIN customer_address ca ON sr.sr_addr_sk = ca.ca_address_sk
    GROUP BY d.d_year, d.d_month_seq, ca.ca_state
),
web_returns_agg AS (
    SELECT d.d_year,
           d.d_month_seq AS month_seq,
           ca.ca_state AS state,
           SUM(wr.wr_net_loss) AS return_loss
    FROM web_returns wr
    JOIN date_dim d ON wr.wr_returned_date_sk = d.d_date_sk
    JOIN customer_address ca ON wr.wr_refunded_addr_sk = ca.ca_address_sk
    GROUP BY d.d_year, d.d_month_seq, ca.ca_state
),
catalog_returns_agg AS (
    SELECT d.d_year,
           d.d_month_seq AS month_seq,
           ca.ca_state AS state,
           SUM(cr.cr_net_loss) AS return_loss
    FROM catalog_returns cr
    JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
    JOIN customer_address ca ON cr.cr_refunded_addr_sk = ca.ca_address_sk
    GROUP BY d.d_year, d.d_month_seq, ca.ca_state
),
sales_combined AS (
    SELECT
        COALESCE(ss.d_year, ws.d_year, cs.d_year) AS year,
        COALESCE(ss.month_seq, ws.month_seq, cs.month_seq) AS month_seq,
        COALESCE(ss.state, ws.state, cs.state) AS state,
        COALESCE(ss.net_sales, 0) + COALESCE(ws.net_sales, 0) + COALESCE(cs.net_sales, 0) AS total_sales,
        COALESCE(ss.net_profit, 0) + COALESCE(ws.net_profit, 0) + COALESCE(cs.net_profit, 0) AS total_profit
    FROM store_sales_agg ss
    FULL OUTER JOIN web_sales_agg ws
        ON ss.d_year = ws.d_year AND ss.month_seq = ws.month_seq AND ss.state = ws.state
    FULL OUTER JOIN catalog_sales_agg cs
        ON COALESCE(ss.d_year, ws.d_year) = cs.d_year
       AND COALESCE(ss.month_seq, ws.month_seq) = cs.month_seq
       AND COALESCE(ss.state, ws.state) = cs.state
),
returns_combined AS (
    SELECT
        COALESCE(sr.d_year, wr.d_year, cr.d_year) AS year,
        COALESCE(sr.month_seq, wr.month_seq, cr.month_seq) AS month_seq,
        COALESCE(sr.state, wr.state, cr.state) AS state,
        COALESCE(sr.return_loss, 0) + COALESCE(wr.return_loss, 0) + COALESCE(cr.return_loss, 0) AS total_return_loss
    FROM store_returns_agg sr
    FULL OUTER JOIN web_returns_agg wr
        ON sr.d_year = wr.d_year AND sr.month_seq = wr.month_seq AND sr.state = wr.state
    FULL OUTER JOIN catalog_returns_agg cr
        ON COALESCE(sr.d_year, wr.d_year) = cr.d_year
       AND COALESCE(sr.month_seq, wr.month_seq) = cr.month_seq
       AND COALESCE(sr.state, wr.state) = cr.state
),
final_agg AS (
    SELECT
        COALESCE(s.year, r.year) AS year,
        COALESCE(s.month_seq, r.month_seq) AS month_seq,
        COALESCE(s.state, r.state) AS state,
        COALESCE(s.total_sales, 0) AS total_sales,
        COALESCE(s.total_profit, 0) AS total_profit,
        COALESCE(r.total_return_loss, 0) AS total_return_loss,
        (COALESCE(s.total_profit, 0) - COALESCE(r.total_return_loss, 0)) AS net_margin
    FROM sales_combined s
    FULL OUTER JOIN returns_combined r
        ON s.year = r.year AND s.month_seq = r.month_seq AND s.state = r.state
)
SELECT
    year,
    month_seq,
    state,
    total_sales,
    total_profit,
    total_return_loss,
    net_margin,
    AVG(net_margin) OVER (PARTITION BY state ORDER BY year, month_seq ROWS BETWEEN 2 PRECEDING AND CURRENT ROW) AS three_month_avg_margin
FROM final_agg
WHERE year IS NOT NULL
ORDER BY year, month_seq, state

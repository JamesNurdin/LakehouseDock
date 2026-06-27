WITH sales_agg AS (
    SELECT
        ca.ca_state AS state,
        td.t_hour AS hour,
        SUM(ss.ss_net_profit) AS total_sales_profit,
        SUM(ss.ss_ext_sales_price) AS total_sales_amount,
        COUNT(*) AS sales_cnt
    FROM store_sales ss
    JOIN time_dim td ON ss.ss_sold_time_sk = td.t_time_sk
    JOIN customer_address ca ON ss.ss_addr_sk = ca.ca_address_sk
    GROUP BY ca.ca_state, td.t_hour
),

returns_detail AS (
    SELECT
        ca.ca_state AS state,
        td.t_hour AS hour,
        r.r_reason_desc AS reason,
        SUM(sr.sr_net_loss) AS total_return_loss,
        COUNT(*) AS return_cnt
    FROM store_returns sr
    JOIN store_sales ss ON sr.sr_ticket_number = ss.ss_ticket_number
    JOIN time_dim td ON ss.ss_sold_time_sk = td.t_time_sk
    JOIN customer_address ca ON ss.ss_addr_sk = ca.ca_address_sk
    JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
    GROUP BY ca.ca_state, td.t_hour, r.r_reason_desc
),

top_reason AS (
    SELECT
        state,
        hour,
        reason,
        total_return_loss,
        return_cnt,
        ROW_NUMBER() OVER (PARTITION BY state, hour ORDER BY total_return_loss DESC) AS rn
    FROM returns_detail
)
SELECT
    s.state,
    s.hour,
    s.total_sales_profit,
    s.total_sales_amount,
    s.sales_cnt,
    tr.reason,
    tr.total_return_loss,
    tr.return_cnt
FROM sales_agg s
LEFT JOIN top_reason tr
    ON s.state = tr.state
   AND s.hour = tr.hour
   AND tr.rn = 1
ORDER BY s.state, s.hour

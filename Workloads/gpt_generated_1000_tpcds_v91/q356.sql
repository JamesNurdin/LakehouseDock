WITH sales_with_returns AS (
    SELECT
        ss.ss_ticket_number,
        ss.ss_sold_date_sk,
        ss.ss_sold_time_sk,
        ss.ss_store_sk,
        ss.ss_addr_sk,
        ss.ss_net_profit,
        ss.ss_ext_sales_price,
        ss.ss_net_paid,
        d.d_date,
        d.d_year,
        d.d_month_seq,
        t.t_shift,
        t.t_minute,
        s.s_store_name AS store_name,
        ca.ca_city,
        ca.ca_state,
        wr.wr_return_amt,
        r.r_reason_desc AS reason_desc,
        cc.cc_name,
        cp.cp_type,
        CASE
            WHEN ss.ss_net_profit > 1000 THEN 'High'
            WHEN ss.ss_net_profit > 0 THEN 'Medium'
            ELSE 'Low'
        END AS profit_category,
        ROW_NUMBER() OVER (PARTITION BY s.s_store_name ORDER BY ss.ss_net_profit DESC) AS profit_rank
    FROM store_sales ss
        INNER JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
        INNER JOIN time_dim t ON ss.ss_sold_time_sk = t.t_time_sk
        INNER JOIN store s ON ss.ss_store_sk = s.s_store_sk
        INNER JOIN customer_address ca ON ss.ss_addr_sk = ca.ca_address_sk
        LEFT JOIN web_returns wr ON wr.wr_returned_date_sk = d.d_date_sk
        LEFT JOIN reason r ON wr.wr_reason_sk = r.r_reason_sk
        FULL OUTER JOIN call_center cc ON d.d_date_sk = cc.cc_closed_date_sk
        LEFT JOIN catalog_page cp ON d.d_date_sk = cp.cp_start_date_sk
)
SELECT
    profit_rank,
    profit_category,
    store_name,
    d_date,
    d_year,
    t_shift,
    t_minute,
    ca_city,
    ca_state,
    ss_ext_sales_price,
    ss_net_profit,
    ss_net_paid,
    wr_return_amt,
    reason_desc,
    cc_name,
    cp_type
FROM sales_with_returns
WHERE d_date BETWEEN DATE '1998-01-01' AND DATE '1998-12-31'
  AND t_shift = 'first'
  AND ca_state = 'CA'
ORDER BY profit_rank, d_date
LIMIT 100

WITH sales_by_state AS (
    SELECT
        ca.ca_state AS state,
        SUM(ss.ss_net_paid) AS total_sales,
        SUM(ss.ss_net_profit) AS total_profit,
        COUNT(*) AS sales_txn_cnt
    FROM store_sales ss
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    JOIN customer_address ca ON ss.ss_addr_sk = ca.ca_address_sk
    WHERE ss.ss_sold_date_sk BETWEEN 2450800 AND 2451100
    GROUP BY ca.ca_state
),
returns_by_state_reason_page AS (
    SELECT
        ca_ret.ca_state AS state,
        r.r_reason_desc AS reason,
        wp.wp_type AS page_type,
        SUM(wr.wr_return_amt) AS total_return_amount,
        SUM(wr.wr_net_loss) AS total_net_loss,
        COUNT(*) AS return_txn_cnt
    FROM web_returns wr
    JOIN customer_address ca_ret ON wr.wr_returning_addr_sk = ca_ret.ca_address_sk
    JOIN reason r ON wr.wr_reason_sk = r.r_reason_sk
    JOIN web_page wp ON wr.wr_web_page_sk = wp.wp_web_page_sk
    WHERE wr.wr_returned_date_sk BETWEEN 2450800 AND 2451100
    GROUP BY ca_ret.ca_state, r.r_reason_desc, wp.wp_type
)
SELECT
    s.state,
    COALESCE(r.reason, 'All') AS reason,
    COALESCE(r.page_type, 'All') AS page_type,
    s.total_sales,
    s.total_profit,
    COALESCE(r.total_return_amount, 0) AS total_return_amount,
    COALESCE(r.total_net_loss, 0) AS total_net_loss,
    s.sales_txn_cnt,
    COALESCE(r.return_txn_cnt, 0) AS return_txn_cnt,
    (s.total_profit - COALESCE(r.total_net_loss, 0)) AS net_profit_after_returns,
    RANK() OVER (ORDER BY (s.total_profit - COALESCE(r.total_net_loss, 0)) DESC) AS profit_rank
FROM sales_by_state s
LEFT JOIN returns_by_state_reason_page r
    ON s.state = r.state
ORDER BY net_profit_after_returns DESC
LIMIT 100

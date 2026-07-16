WITH returns_agg AS (
    SELECT
        ca.ca_state AS state,
        d.d_year,
        d.d_month_seq AS month_seq,
        SUM(cr.cr_net_loss) AS total_return_net_loss,
        COUNT(*) AS return_cnt
    FROM catalog_returns cr
    JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
    JOIN customer_address ca ON cr.cr_refunded_addr_sk = ca.ca_address_sk
    WHERE d.d_year = 2001
    GROUP BY ca.ca_state, d.d_year, d.d_month_seq
),
sales_agg AS (
    SELECT
        ca.ca_state AS state,
        d.d_year,
        d.d_month_seq AS month_seq,
        SUM(ss.ss_net_profit) AS total_store_net_profit,
        COUNT(*) AS sales_cnt
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN customer_address ca ON ss.ss_addr_sk = ca.ca_address_sk
    WHERE d.d_year = 2001
    GROUP BY ca.ca_state, d.d_year, d.d_month_seq
)
SELECT
    r.state,
    r.d_year,
    r.month_seq,
    r.total_return_net_loss,
    r.return_cnt,
    COALESCE(s.total_store_net_profit, 0) AS total_store_net_profit,
    COALESCE(s.sales_cnt, 0) AS sales_cnt,
    r.total_return_net_loss - COALESCE(s.total_store_net_profit, 0) AS net_loss_minus_profit,
    RANK() OVER (ORDER BY r.total_return_net_loss DESC) AS loss_rank
FROM returns_agg r
LEFT JOIN sales_agg s
    ON r.state = s.state
    AND r.d_year = s.d_year
    AND r.month_seq = s.month_seq
WHERE r.total_return_net_loss > 5000
ORDER BY r.total_return_net_loss DESC
LIMIT 20

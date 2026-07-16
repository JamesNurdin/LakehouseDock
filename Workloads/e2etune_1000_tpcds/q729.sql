WITH sales_by_state AS (
    SELECT ca.ca_state AS state,
           SUM(ss.ss_net_paid_inc_tax) AS total_sales,
           SUM(ss.ss_net_profit) AS total_profit
    FROM store_sales ss
    JOIN customer_address ca ON ss.ss_addr_sk = ca.ca_address_sk
    WHERE ss.ss_sold_date_sk BETWEEN 2451010 AND 2451100
    GROUP BY ca.ca_state
),
returns_by_state_reason AS (
    SELECT ca.ca_state AS state,
           r.r_reason_desc AS reason_desc,
           SUM(cr.cr_net_loss) AS total_net_loss,
           SUM(cr.cr_return_amount) AS total_return_amount
    FROM catalog_returns cr
    JOIN customer_address ca ON cr.cr_refunded_addr_sk = ca.ca_address_sk
    JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
    WHERE cr.cr_returned_date_sk BETWEEN 2451010 AND 2451100
    GROUP BY ca.ca_state, r.r_reason_desc
    UNION ALL
    SELECT ca.ca_state AS state,
           r.r_reason_desc AS reason_desc,
           SUM(wr.wr_net_loss) AS total_net_loss,
           SUM(wr.wr_return_amt) AS total_return_amount
    FROM web_returns wr
    JOIN customer_address ca ON wr.wr_refunded_addr_sk = ca.ca_address_sk
    JOIN reason r ON wr.wr_reason_sk = r.r_reason_sk
    WHERE wr.wr_returned_date_sk BETWEEN 2451010 AND 2451100
    GROUP BY ca.ca_state, r.r_reason_desc
),
agg_returns AS (
    SELECT state,
           reason_desc,
           SUM(total_net_loss) AS net_loss,
           SUM(total_return_amount) AS return_amount
    FROM returns_by_state_reason
    GROUP BY state, reason_desc
)
SELECT
    s.state,
    a.reason_desc,
    s.total_sales,
    a.net_loss,
    a.return_amount,
    (a.net_loss / NULLIF(s.total_sales, 0)) AS loss_to_sales_ratio,
    RANK() OVER (ORDER BY (a.net_loss / NULLIF(s.total_sales, 0)) DESC) AS loss_ratio_rank
FROM sales_by_state s
JOIN agg_returns a ON s.state = a.state
WHERE s.total_sales > 0
ORDER BY loss_to_sales_ratio DESC
LIMIT 10

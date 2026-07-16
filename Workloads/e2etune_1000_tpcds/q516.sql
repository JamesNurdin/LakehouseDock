WITH catalog_ret AS (
    SELECT
        cr.cr_returned_date_sk AS returned_date_sk,
        cr.cr_net_loss AS net_loss,
        cr.cr_refunded_cash AS refunded_cash,
        cr.cr_return_quantity AS return_qty,
        cc.cc_name AS call_center_name,
        ca.ca_state AS state
    FROM catalog_returns cr
    JOIN call_center cc
        ON cr.cr_call_center_sk = cc.cc_call_center_sk
    JOIN customer_address ca
        ON cr.cr_refunded_addr_sk = ca.ca_address_sk
    WHERE cc.cc_manager = 'Bob Belcher'
        AND ca.ca_state IN ('CA', 'TX', 'NY')
),
store_ret AS (
    SELECT
        sr.sr_returned_date_sk AS returned_date_sk,
        sr.sr_net_loss AS net_loss,
        sr.sr_refunded_cash AS refunded_cash,
        sr.sr_return_quantity AS return_qty,
        CAST(NULL AS varchar) AS call_center_name,
        ca.ca_state AS state
    FROM store_returns sr
    JOIN customer_address ca
        ON sr.sr_addr_sk = ca.ca_address_sk
    WHERE ca.ca_state IN ('CA', 'TX', 'NY')
),
web_ret AS (
    SELECT
        wr.wr_returned_date_sk AS returned_date_sk,
        wr.wr_net_loss AS net_loss,
        wr.wr_refunded_cash AS refunded_cash,
        wr.wr_return_quantity AS return_qty,
        CAST(NULL AS varchar) AS call_center_name,
        ca.ca_state AS state
    FROM web_returns wr
    JOIN customer_address ca
        ON wr.wr_refunded_addr_sk = ca.ca_address_sk
    WHERE ca.ca_state IN ('CA', 'TX', 'NY')
),
all_returns AS (
    SELECT * FROM catalog_ret
    UNION ALL
    SELECT * FROM store_ret
    UNION ALL
    SELECT * FROM web_ret
)
SELECT
    COALESCE(call_center_name, 'All Centers') AS call_center,
    state,
    COUNT(*) AS total_returns,
    SUM(net_loss) AS total_net_loss,
    SUM(refunded_cash) AS total_refunded_cash,
    AVG(return_qty) AS avg_return_quantity
FROM all_returns
WHERE returned_date_sk BETWEEN 2450000 AND 2455000
    AND net_loss > 0
GROUP BY COALESCE(call_center_name, 'All Centers'), state
ORDER BY total_net_loss DESC
LIMIT 100

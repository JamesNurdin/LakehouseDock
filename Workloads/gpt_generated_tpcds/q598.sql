WITH joined_data AS (
    SELECT
        ca.ca_state,
        r.r_reason_desc,
        wp.wp_type,
        cd.cd_gender,
        ws.ws_net_profit,
        wr.wr_return_amt,
        wr.wr_net_loss
    FROM web_returns wr
    JOIN web_sales ws
        ON wr.wr_order_number = ws.ws_order_number
        AND wr.wr_item_sk = ws.ws_item_sk
    JOIN customer_address ca
        ON ws.ws_bill_addr_sk = ca.ca_address_sk
    JOIN reason r
        ON wr.wr_reason_sk = r.r_reason_sk
    JOIN web_page wp
        ON ws.ws_web_page_sk = wp.wp_web_page_sk
    JOIN customer_demographics cd
        ON ws.ws_bill_cdemo_sk = cd.cd_demo_sk
)
SELECT
    ca_state,
    r_reason_desc,
    wp_type,
    cd_gender,
    COUNT(*) AS return_count,
    SUM(wr_return_amt) AS total_return_amount,
    SUM(wr_net_loss) AS total_net_loss,
    SUM(ws_net_profit) AS total_sales_profit,
    AVG(wr_net_loss) AS avg_net_loss
FROM joined_data
GROUP BY ca_state, r_reason_desc, wp_type, cd_gender
ORDER BY total_net_loss DESC
LIMIT 100

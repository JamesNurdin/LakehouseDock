WITH returns_detail AS (
    SELECT
        r.r_reason_desc AS reason_desc,
        cd.cd_gender AS gender,
        cd.cd_marital_status AS marital_status,
        SUM(wr.wr_net_loss) AS total_net_loss,
        SUM(wr.wr_return_amt_inc_tax) AS total_return_amount,
        COUNT(*) AS return_cnt,
        AVG(wr.wr_return_amt_inc_tax) AS avg_return_amount,
        SUM(ws.ws_ext_sales_price) AS total_original_sales,
        AVG(date_diff('day',
            date_add('day', ws.ws_sold_date_sk, DATE '1970-01-01'),
            date_add('day', wr.wr_returned_date_sk, DATE '1970-01-01')
        )) AS avg_days_to_return
    FROM web_returns wr
    JOIN web_sales ws
        ON wr.wr_order_number = ws.ws_order_number
       AND wr.wr_item_sk = ws.ws_item_sk
    JOIN reason r
        ON wr.wr_reason_sk = r.r_reason_sk
    JOIN customer_demographics cd
        ON wr.wr_refunded_cdemo_sk = cd.cd_demo_sk
    JOIN web_page wp
        ON wr.wr_web_page_sk = wp.wp_web_page_sk
    WHERE wr.wr_returned_date_sk BETWEEN 2450000 AND 2452000
      AND wp.wp_type = 'product'
    GROUP BY r.r_reason_desc, cd.cd_gender, cd.cd_marital_status
)
SELECT
    reason_desc,
    gender,
    marital_status,
    total_net_loss,
    total_return_amount,
    return_cnt,
    avg_return_amount,
    total_original_sales,
    avg_days_to_return,
    RANK() OVER (ORDER BY total_net_loss DESC) AS net_loss_rank
FROM returns_detail
ORDER BY total_net_loss DESC
LIMIT 50

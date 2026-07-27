WITH customer_activity AS (
    SELECT
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        SUM(ws.ws_net_profit) AS web_profit,
        SUM(-sr.sr_net_loss) AS store_profit,
        SUM(-cr.cr_net_loss) AS catalog_profit
    FROM
        customer c
        JOIN store_returns sr ON sr.sr_customer_sk = c.c_customer_sk
        JOIN store s ON sr.sr_store_sk = s.s_store_sk
        JOIN catalog_returns cr ON cr.cr_refunded_customer_sk = c.c_customer_sk
        JOIN call_center cc ON cr.cr_call_center_sk = cc.cc_call_center_sk
        JOIN catalog_page cp ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
        JOIN web_sales ws ON ws.ws_bill_customer_sk = c.c_customer_sk
        JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
    WHERE
        s.s_zip = '61933'
        AND s.s_rec_start_date >= DATE '2000-01-01'
        AND cp.cp_catalog_number IN (7, 16)
        AND cr.cr_return_quantity > 20
        AND ws.ws_quantity >= 2
        AND cc.cc_state = 'CA'
    GROUP BY
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name
)
SELECT
    c_customer_sk,
    c_first_name,
    c_last_name,
    web_profit,
    store_profit,
    catalog_profit,
    (web_profit + store_profit + catalog_profit) AS total_profit,
    RANK() OVER (ORDER BY (web_profit + store_profit + catalog_profit) DESC) AS profit_rank
FROM customer_activity
ORDER BY total_profit DESC
LIMIT 100

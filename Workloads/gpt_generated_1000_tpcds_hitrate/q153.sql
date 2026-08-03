WITH base AS (
    SELECT
        d.d_date,
        d.d_year,
        ca.ca_city,
        cp.cp_catalog_page_id,
        ss.ss_ticket_number,
        ss.ss_quantity,
        ss.ss_net_paid,
        ss.ss_net_profit,
        sr.sr_return_quantity,
        sr.sr_net_loss,
        cr.cr_return_amount,
        cr.cr_return_tax,
        wr.wr_return_amt,
        wr.wr_return_tax,
        ws.ws_order_number,
        ws.ws_quantity AS ws_quantity,
        ws.ws_net_profit AS ws_net_profit,
        wp.wp_url
    FROM date_dim d
    JOIN store_sales ss
        ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN store_returns sr
        ON sr.sr_ticket_number = ss.ss_ticket_number
    JOIN customer_address ca
        ON ss.ss_addr_sk = ca.ca_address_sk
    JOIN catalog_page cp
        ON cp.cp_start_date_sk = d.d_date_sk
    JOIN catalog_returns cr
        ON cr.cr_returned_date_sk = d.d_date_sk
        AND cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN web_sales ws
        ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN web_returns wr
        ON wr.wr_order_number = ws.ws_order_number
        AND wr.wr_returned_date_sk = d.d_date_sk
    JOIN web_page wp
        ON ws.ws_web_page_sk = wp.wp_web_page_sk
)
SELECT
    d_date,
    d_year,
    ca_city,
    cp_catalog_page_id,
    ss_ticket_number,
    ws_order_number,
    ss_quantity,
    ws_quantity,
    qty,
    cr_return_amount,
    cr_return_tax,
    wr_return_amt,
    wr_return_tax,
    sr_return_quantity,
    sr_net_loss,
    ws_net_profit,
    RANK() OVER (PARTITION BY d_year ORDER BY ws_net_profit DESC) AS profit_rank
FROM base
CROSS JOIN UNNEST(ARRAY[ss_quantity, ws_quantity]) AS t(qty)
WHERE
    d_year BETWEEN 2000 AND 2002
    AND ca_city = 'Los Angeles'
    AND ss_quantity > (SELECT AVG(ss_quantity) FROM store_sales)
    AND ws_net_profit > 0
    AND cr_return_amount > 100
    AND ws_order_number NOT IN (SELECT cr_order_number FROM catalog_returns)
    AND ws_net_profit > (
        SELECT MAX(ss_net_profit)
        FROM store_sales
        WHERE ss_sold_date_sk = (SELECT MIN(d_date_sk) FROM date_dim)
    )
ORDER BY profit_rank, d_date
LIMIT 100

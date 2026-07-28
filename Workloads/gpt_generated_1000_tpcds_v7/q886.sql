WITH filtered AS (
    SELECT
        i.i_category,
        i.i_manufact,
        sr.sr_return_amt,
        sr.sr_net_loss,
        ws.ws_net_paid,
        ws.ws_sales_price,
        ws.ws_ext_list_price,
        ws.ws_ship_mode_sk,
        ws.ws_ship_date_sk,
        sr.sr_store_sk,
        sr.sr_reversed_charge,
        sr.sr_ticket_number
    FROM
        tpcds.item i
        JOIN tpcds.store_returns sr ON sr.sr_item_sk = i.i_item_sk
        JOIN tpcds.web_sales ws ON ws.ws_item_sk = i.i_item_sk
    WHERE
        i.i_category = 'Electronics'
        AND i.i_manufact_id = 460
        AND sr.sr_store_sk IN (283, 416)
        AND sr.sr_reversed_charge > 10
        AND ws.ws_ship_mode_sk = 13
        AND ws.ws_ext_list_price > 3000
        AND ws.ws_ship_date_sk BETWEEN 2451700 AND 2451800
)
SELECT
    i_category,
    i_manufact,
    SUM(sr_return_amt) AS total_return_amount,
    SUM(sr_net_loss) AS total_net_loss,
    SUM(ws_net_paid) AS total_sales_amount,
    COUNT(DISTINCT sr_ticket_number) AS distinct_return_tickets,
    AVG(ws_sales_price) AS avg_sales_price,
    MIN(ws_ext_list_price) AS min_list_price,
    MAX(ws_ext_list_price) AS max_list_price
FROM
    filtered
GROUP BY
    i_category,
    i_manufact
ORDER BY
    total_return_amount DESC

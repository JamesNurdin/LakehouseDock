WITH unified_sales AS (
    SELECT
        d_sales.d_year,
        d_sales.d_month_seq,
        i.i_category,
        ss.ss_quantity AS quantity,
        ss.ss_net_paid AS net_paid,
        ss.ss_net_profit AS net_profit,
        COALESCE(sr.sr_return_quantity, 0) AS return_quantity,
        COALESCE(sr.sr_return_amt, 0) AS return_amount
    FROM store_sales ss
    JOIN date_dim d_sales ON ss.ss_sold_date_sk = d_sales.d_date_sk
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    LEFT JOIN store_returns sr ON ss.ss_ticket_number = sr.sr_ticket_number
    LEFT JOIN date_dim d_return ON sr.sr_returned_date_sk = d_return.d_date_sk
    WHERE d_sales.d_date >= DATE '2022-01-01' AND d_sales.d_date < DATE '2023-01-01'
      AND (d_return.d_date IS NULL OR (d_return.d_date >= DATE '2022-01-01' AND d_return.d_date < DATE '2023-01-01'))

    UNION ALL

    SELECT
        d_sales.d_year,
        d_sales.d_month_seq,
        i.i_category,
        cs.cs_quantity AS quantity,
        cs.cs_net_paid AS net_paid,
        cs.cs_net_profit AS net_profit,
        COALESCE(cr.cr_return_quantity, 0) AS return_quantity,
        COALESCE(cr.cr_return_amount, 0) AS return_amount
    FROM catalog_sales cs
    JOIN date_dim d_sales ON cs.cs_sold_date_sk = d_sales.d_date_sk
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    LEFT JOIN catalog_returns cr ON cs.cs_order_number = cr.cr_order_number
    LEFT JOIN date_dim d_return ON cr.cr_returned_date_sk = d_return.d_date_sk
    WHERE d_sales.d_date >= DATE '2022-01-01' AND d_sales.d_date < DATE '2023-01-01'
      AND (d_return.d_date IS NULL OR (d_return.d_date >= DATE '2022-01-01' AND d_return.d_date < DATE '2023-01-01'))

    UNION ALL

    SELECT
        d_sales.d_year,
        d_sales.d_month_seq,
        i.i_category,
        ws.ws_quantity AS quantity,
        ws.ws_net_paid AS net_paid,
        ws.ws_net_profit AS net_profit,
        COALESCE(wr.wr_return_quantity, 0) AS return_quantity,
        COALESCE(wr.wr_return_amt, 0) AS return_amount
    FROM web_sales ws
    JOIN date_dim d_sales ON ws.ws_sold_date_sk = d_sales.d_date_sk
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    LEFT JOIN web_returns wr ON ws.ws_order_number = wr.wr_order_number
    LEFT JOIN date_dim d_return ON wr.wr_returned_date_sk = d_return.d_date_sk
    WHERE d_sales.d_date >= DATE '2022-01-01' AND d_sales.d_date < DATE '2023-01-01'
      AND (d_return.d_date IS NULL OR (d_return.d_date >= DATE '2022-01-01' AND d_return.d_date < DATE '2023-01-01'))
)
SELECT
    d_year,
    d_month_seq,
    i_category,
    SUM(quantity) AS total_quantity_sold,
    SUM(net_paid) AS total_net_paid,
    SUM(net_profit) AS total_net_profit,
    SUM(return_quantity) AS total_return_quantity,
    SUM(return_amount) AS total_return_amount
FROM unified_sales
GROUP BY d_year, d_month_seq, i_category
ORDER BY d_year, d_month_seq, i_category

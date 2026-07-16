SELECT
    d_year,
    i_category,
    channel,
    SUM(sale_amount) AS total_sales,
    SUM(sale_profit) AS total_profit,
    SUM(return_amount) AS total_returns,
    COUNT(*) AS sales_transactions
FROM (
    SELECT
        d.d_year AS d_year,
        i.i_category AS i_category,
        'store' AS channel,
        ss.ss_net_paid AS sale_amount,
        ss.ss_net_profit AS sale_profit,
        COALESCE(sr.sr_return_amt, 0) AS return_amount
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    LEFT JOIN store_returns sr ON ss.ss_ticket_number = sr.sr_ticket_number
    WHERE d.d_year BETWEEN 1999 AND 2001

    UNION ALL

    SELECT
        d.d_year AS d_year,
        i.i_category AS i_category,
        'web' AS channel,
        ws.ws_net_paid AS sale_amount,
        ws.ws_net_profit AS sale_profit,
        COALESCE(wr.wr_return_amt, 0) AS return_amount
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    LEFT JOIN web_returns wr ON ws.ws_order_number = wr.wr_order_number
    WHERE d.d_year BETWEEN 1999 AND 2001

    UNION ALL

    SELECT
        d.d_year AS d_year,
        i.i_category AS i_category,
        'catalog' AS channel,
        cs.cs_net_paid AS sale_amount,
        cs.cs_net_profit AS sale_profit,
        COALESCE(cr.cr_return_amount, 0) AS return_amount
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    LEFT JOIN catalog_returns cr ON cs.cs_order_number = cr.cr_order_number
    WHERE d.d_year BETWEEN 1999 AND 2001
) t
GROUP BY d_year, i_category, channel
ORDER BY total_sales DESC
LIMIT 100

SELECT
    channel,
    sale_year,
    category,
    SUM(net_sales) AS total_sales,
    SUM(net_returns) AS total_returns,
    SUM(net_sales - net_returns) AS net_revenue
FROM (
    SELECT
        'store' AS channel,
        d.d_year AS sale_year,
        i.i_category AS category,
        ss.ss_net_paid AS net_sales,
        COALESCE(sr.sr_net_loss, 0) AS net_returns
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    LEFT JOIN store_returns sr
        ON ss.ss_ticket_number = sr.sr_ticket_number
        AND ss.ss_store_sk = sr.sr_store_sk
        AND d.d_date_sk = sr.sr_returned_date_sk

    UNION ALL

    SELECT
        'catalog' AS channel,
        d.d_year AS sale_year,
        i.i_category AS category,
        cs.cs_net_paid AS net_sales,
        COALESCE(cr.cr_net_loss, 0) AS net_returns
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    LEFT JOIN catalog_returns cr
        ON cs.cs_order_number = cr.cr_order_number
        AND d.d_date_sk = cr.cr_returned_date_sk

    UNION ALL

    SELECT
        'web' AS channel,
        d.d_year AS sale_year,
        i.i_category AS category,
        ws.ws_net_paid AS net_sales,
        COALESCE(wr.wr_net_loss, 0) AS net_returns
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    LEFT JOIN web_returns wr
        ON ws.ws_order_number = wr.wr_order_number
        AND d.d_date_sk = wr.wr_returned_date_sk
) t
GROUP BY channel, sale_year, category
ORDER BY net_revenue DESC
LIMIT 100

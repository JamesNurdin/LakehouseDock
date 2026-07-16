WITH unified_sales AS (
    SELECT 'store' AS channel,
        ss.ss_sold_date_sk AS date_sk,
        ss.ss_item_sk AS item_sk,
        ss.ss_store_sk AS location_sk,
        ss.ss_quantity AS quantity,
        ss.ss_net_paid AS net_paid,
        ss.ss_net_profit AS net_profit,
        ss.ss_ticket_number AS order_number
    FROM store_sales ss
    UNION ALL
    SELECT 'catalog' AS channel,
        cs.cs_sold_date_sk AS date_sk,
        cs.cs_item_sk AS item_sk,
        cs.cs_call_center_sk AS location_sk,
        cs.cs_quantity AS quantity,
        cs.cs_net_paid AS net_paid,
        cs.cs_net_profit AS net_profit,
        cs.cs_order_number AS order_number
    FROM catalog_sales cs
    UNION ALL
    SELECT 'web' AS channel,
        ws.ws_sold_date_sk AS date_sk,
        ws.ws_item_sk AS item_sk,
        ws.ws_web_page_sk AS location_sk,
        ws.ws_quantity AS quantity,
        ws.ws_net_paid AS net_paid,
        ws.ws_net_profit AS net_profit,
        ws.ws_order_number AS order_number
    FROM web_sales ws
),
unified_returns AS (
    SELECT 'store' AS channel,
        sr.sr_returned_date_sk AS date_sk,
        sr.sr_item_sk AS item_sk,
        sr.sr_store_sk AS location_sk,
        sr.sr_return_quantity AS quantity,
        sr.sr_return_amt AS return_amount,
        sr.sr_net_loss AS net_loss,
        sr.sr_ticket_number AS order_number
    FROM store_returns sr
    UNION ALL
    SELECT 'catalog' AS channel,
        cr.cr_returned_date_sk AS date_sk,
        cr.cr_item_sk AS item_sk,
        cr.cr_call_center_sk AS location_sk,
        cr.cr_return_quantity AS quantity,
        cr.cr_return_amount AS return_amount,
        cr.cr_net_loss AS net_loss,
        cr.cr_order_number AS order_number
    FROM catalog_returns cr
    UNION ALL
    SELECT 'web' AS channel,
        wr.wr_returned_date_sk AS date_sk,
        wr.wr_item_sk AS item_sk,
        wr.wr_web_page_sk AS location_sk,
        wr.wr_return_quantity AS quantity,
        wr.wr_return_amt AS return_amount,
        wr.wr_net_loss AS net_loss,
        wr.wr_order_number AS order_number
    FROM web_returns wr
),
sales_returns AS (
    SELECT 
        us.channel,
        dd.d_year,
        dd.d_month_seq AS month,
        i.i_category,
        i.i_brand,
        SUM(us.net_paid) AS total_sales,
        SUM(us.net_profit) AS total_profit,
        SUM(COALESCE(ur.return_amount, 0)) AS total_return_amount,
        SUM(COALESCE(ur.net_loss, 0)) AS total_return_loss,
        SUM(us.net_profit) - SUM(COALESCE(ur.net_loss, 0)) AS net_profit_after_returns,
        SUM(us.net_paid) - SUM(COALESCE(ur.return_amount, 0)) AS net_sales_after_returns
    FROM unified_sales us
    LEFT JOIN unified_returns ur
        ON us.channel = ur.channel
        AND us.order_number = ur.order_number
        AND us.item_sk = ur.item_sk
    JOIN date_dim dd ON us.date_sk = dd.d_date_sk
    JOIN item i ON us.item_sk = i.i_item_sk
    GROUP BY GROUPING SETS (
        (us.channel, dd.d_year, dd.d_month_seq, i.i_category, i.i_brand),
        (us.channel, dd.d_year, dd.d_month_seq, i.i_category),
        (us.channel, dd.d_year, i.i_category, i.i_brand),
        (us.channel, dd.d_year, i.i_category),
        (us.channel, dd.d_year),
        (us.channel)
    )
),
ranked_items AS (
    SELECT 
        us.channel,
        dd.d_year,
        us.item_sk,
        i.i_product_name,
        SUM(us.net_profit) AS profit,
        ROW_NUMBER() OVER (PARTITION BY us.channel, dd.d_year ORDER BY SUM(us.net_profit) DESC) AS profit_rank
    FROM unified_sales us
    JOIN date_dim dd ON us.date_sk = dd.d_date_sk
    JOIN item i ON us.item_sk = i.i_item_sk
    GROUP BY us.channel, dd.d_year, us.item_sk, i.i_product_name
    HAVING SUM(us.net_profit) > 0
)
SELECT 
    sr.channel,
    sr.d_year,
    sr.month,
    sr.i_category,
    sr.i_brand,
    sr.total_sales,
    sr.total_profit,
    sr.total_return_amount,
    sr.total_return_loss,
    sr.net_profit_after_returns,
    sr.net_sales_after_returns,
    ri.profit_rank,
    ri.profit AS top_item_profit,
    ri.product_name AS top_item_name,
    SUM(sr.net_profit_after_returns) OVER (PARTITION BY sr.channel ORDER BY sr.d_year, COALESCE(sr.month, 0) ROWS UNBOUNDED PRECEDING) AS cumulative_profit
FROM sales_returns sr
LEFT JOIN (
    SELECT channel, d_year, profit_rank, profit, i_product_name AS product_name
    FROM ranked_items
    WHERE profit_rank = 1
) ri ON sr.channel = ri.channel AND sr.d_year = ri.d_year
WHERE sr.channel IS NOT NULL
ORDER BY sr.channel, sr.d_year, sr.month, sr.i_category

WITH sales AS (
    SELECT 'store' AS channel,
           ss.ss_sold_date_sk AS date_sk,
           ss.ss_item_sk AS item_sk,
           ss.ss_quantity AS quantity,
           ss.ss_net_profit AS net_profit,
           ss.ss_ticket_number AS order_num
    FROM store_sales ss
    UNION ALL
    SELECT 'web' AS channel,
           ws.ws_sold_date_sk,
           ws.ws_item_sk,
           ws.ws_quantity,
           ws.ws_net_profit,
           ws.ws_order_number
    FROM web_sales ws
    UNION ALL
    SELECT 'catalog' AS channel,
           cs.cs_sold_date_sk,
           cs.cs_item_sk,
           cs.cs_quantity,
           cs.cs_net_profit,
           cs.cs_order_number
    FROM catalog_sales cs
),
returns AS (
    SELECT 'store' AS channel,
           sr.sr_returned_date_sk AS date_sk,
           sr.sr_item_sk AS item_sk,
           sr.sr_return_quantity AS quantity,
           sr.sr_net_loss AS net_loss
    FROM store_returns sr
    UNION ALL
    SELECT 'web' AS channel,
           wr.wr_returned_date_sk,
           wr.wr_item_sk,
           wr.wr_return_quantity,
           wr.wr_net_loss
    FROM web_returns wr
    UNION ALL
    SELECT 'catalog' AS channel,
           cr.cr_returned_date_sk,
           cr.cr_item_sk,
           cr.cr_return_quantity,
           cr.cr_net_loss
    FROM catalog_returns cr
),
sales_agg AS (
    SELECT
        s.channel,
        d.d_year,
        d.d_month_seq,
        i.i_category,
        SUM(s.net_profit) AS gross_profit,
        SUM(s.quantity) AS sold_quantity,
        COUNT(DISTINCT s.order_num) AS orders,
        SUM(COALESCE(r.net_loss, 0)) AS return_loss,
        SUM(COALESCE(r.quantity, 0)) AS returned_quantity
    FROM sales s
    LEFT JOIN returns r
        ON s.channel = r.channel
       AND s.date_sk = r.date_sk
       AND s.item_sk = r.item_sk
    JOIN date_dim d ON s.date_sk = d.d_date_sk
    JOIN item i ON s.item_sk = i.i_item_sk
    GROUP BY s.channel, d.d_year, d.d_month_seq, i.i_category
),
profit_calc AS (
    SELECT
        channel,
        d_year,
        d_month_seq,
        i_category,
        gross_profit,
        sold_quantity,
        orders,
        return_loss,
        returned_quantity,
        (gross_profit - return_loss) AS net_profit_adj,
        (sold_quantity - returned_quantity) AS net_quantity,
        RANK() OVER (PARTITION BY d_year, d_month_seq ORDER BY (gross_profit - return_loss) DESC) AS profit_rank,
        ROW_NUMBER() OVER (PARTITION BY d_year, d_month_seq ORDER BY (sold_quantity - returned_quantity) DESC) AS quantity_rank,
        SUM(gross_profit - return_loss) OVER (PARTITION BY channel, i_category ORDER BY d_year, d_month_seq ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS cum_net_profit
    FROM sales_agg
)
SELECT
    d_year,
    d_month_seq,
    i_category,
    channel,
    net_profit_adj,
    net_quantity,
    orders,
    profit_rank,
    quantity_rank,
    cum_net_profit
FROM profit_calc
WHERE profit_rank <= 5
ORDER BY d_year, d_month_seq, channel, profit_rank

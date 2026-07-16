WITH base_sales AS (
    SELECT
        d.d_year AS sale_year,
        d.d_month_seq AS month_seq,
        i.i_item_id AS item_id,
        i.i_product_name AS product_name,
        'store' AS channel,
        ss.ss_net_paid AS net_paid,
        ss.ss_net_profit AS net_profit,
        ss.ss_quantity AS quantity,
        ss.ss_ticket_number AS transaction_id
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    WHERE d.d_year = 2001
    UNION ALL
    SELECT
        d.d_year AS sale_year,
        d.d_month_seq AS month_seq,
        i.i_item_id AS item_id,
        i.i_product_name AS product_name,
        'catalog' AS channel,
        cs.cs_net_paid AS net_paid,
        cs.cs_net_profit AS net_profit,
        cs.cs_quantity AS quantity,
        cs.cs_order_number AS transaction_id
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    WHERE d.d_year = 2001
    UNION ALL
    SELECT
        d.d_year AS sale_year,
        d.d_month_seq AS month_seq,
        i.i_item_id AS item_id,
        i.i_product_name AS product_name,
        'web' AS channel,
        ws.ws_net_paid AS net_paid,
        ws.ws_net_profit AS net_profit,
        ws.ws_quantity AS quantity,
        ws.ws_order_number AS transaction_id
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    WHERE d.d_year = 2001
),
base_returns AS (
    SELECT
        d.d_year AS sale_year,
        d.d_month_seq AS month_seq,
        i.i_item_id AS item_id,
        'store' AS channel,
        sr.sr_net_loss AS net_loss,
        sr.sr_return_quantity AS return_qty
    FROM store_returns sr
    JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
    JOIN item i ON sr.sr_item_sk = i.i_item_sk
    WHERE d.d_year = 2001
    UNION ALL
    SELECT
        d.d_year AS sale_year,
        d.d_month_seq AS month_seq,
        i.i_item_id AS item_id,
        'catalog' AS channel,
        cr.cr_net_loss AS net_loss,
        cr.cr_return_quantity AS return_qty
    FROM catalog_returns cr
    JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
    JOIN item i ON cr.cr_item_sk = i.i_item_sk
    WHERE d.d_year = 2001
    UNION ALL
    SELECT
        d.d_year AS sale_year,
        d.d_month_seq AS month_seq,
        i.i_item_id AS item_id,
        'web' AS channel,
        wr.wr_net_loss AS net_loss,
        wr.wr_return_quantity AS return_qty
    FROM web_returns wr
    JOIN date_dim d ON wr.wr_returned_date_sk = d.d_date_sk
    JOIN item i ON wr.wr_item_sk = i.i_item_sk
    WHERE d.d_year = 2001
),
sales_agg AS (
    SELECT
        sale_year,
        month_seq,
        item_id,
        product_name,
        channel,
        SUM(net_paid) AS total_net_paid,
        SUM(net_profit) AS total_net_profit,
        SUM(quantity) AS total_quantity,
        COUNT(DISTINCT transaction_id) AS total_transactions
    FROM base_sales
    GROUP BY
        sale_year,
        month_seq,
        item_id,
        product_name,
        channel
),
returns_agg AS (
    SELECT
        sale_year,
        month_seq,
        item_id,
        channel,
        SUM(net_loss) AS total_net_loss,
        SUM(return_qty) AS total_return_qty
    FROM base_returns
    GROUP BY
        sale_year,
        month_seq,
        item_id,
        channel
),
combined AS (
    SELECT
        s.sale_year,
        s.month_seq,
        s.item_id,
        s.product_name,
        s.channel,
        s.total_net_paid,
        s.total_net_profit,
        s.total_quantity,
        s.total_transactions,
        COALESCE(r.total_net_loss, 0) AS total_net_loss,
        COALESCE(r.total_return_qty, 0) AS total_return_qty
    FROM sales_agg s
    LEFT JOIN returns_agg r
      ON s.sale_year = r.sale_year
     AND s.month_seq = r.month_seq
     AND s.item_id = r.item_id
     AND s.channel = r.channel
),
ranked AS (
    SELECT
        *,
        ROW_NUMBER() OVER (PARTITION BY sale_year, month_seq ORDER BY total_net_profit DESC) AS profit_rank,
        PERCENT_RANK() OVER (PARTITION BY sale_year ORDER BY total_net_profit) AS profit_percentile,
        SUM(total_net_profit) OVER (PARTITION BY sale_year, month_seq) AS month_total_profit,
        AVG(total_net_profit) OVER (PARTITION BY sale_year ORDER BY month_seq ROWS BETWEEN 2 PRECEDING AND CURRENT ROW) AS moving_avg_3_months
    FROM combined
)
SELECT
    sale_year,
    month_seq,
    item_id,
    product_name,
    channel,
    total_net_paid,
    total_net_profit,
    total_quantity,
    total_transactions,
    total_net_loss,
    total_return_qty,
    profit_rank,
    profit_percentile,
    month_total_profit,
    moving_avg_3_months
FROM ranked
WHERE profit_rank <= 10
ORDER BY sale_year, month_seq, profit_rank
LIMIT 200

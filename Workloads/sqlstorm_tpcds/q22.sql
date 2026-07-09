WITH sales AS (
    SELECT
        cs.cs_item_sk AS item_sk,
        cs.cs_sold_date_sk AS date_sk,
        d.d_date AS sold_date,
        date_trunc('month', d.d_date) AS month_start,
        'catalog' AS channel,
        cs.cs_quantity AS quantity,
        cs.cs_ext_sales_price AS sales_amount,
        cs.cs_ext_discount_amt AS discount_amount,
        cs.cs_net_profit AS net_profit
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    WHERE d.d_date >= date_add('year', -2, DATE '2024-10-01')
    UNION ALL
    SELECT
        ss.ss_item_sk,
        ss.ss_sold_date_sk,
        d.d_date,
        date_trunc('month', d.d_date),
        'store',
        ss.ss_quantity,
        ss.ss_ext_sales_price,
        ss.ss_ext_discount_amt,
        ss.ss_net_profit
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    WHERE d.d_date >= date_add('year', -2, DATE '2024-10-01')
    UNION ALL
    SELECT
        ws.ws_item_sk,
        ws.ws_sold_date_sk,
        d.d_date,
        date_trunc('month', d.d_date),
        'web',
        ws.ws_quantity,
        ws.ws_ext_sales_price,
        ws.ws_ext_discount_amt,
        ws.ws_net_profit
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE d.d_date >= date_add('year', -2, DATE '2024-10-01')
),
returns AS (
    SELECT
        cr.cr_item_sk AS item_sk,
        cr.cr_returned_date_sk AS date_sk,
        d.d_date AS return_date,
        date_trunc('month', d.d_date) AS month_start,
        'catalog' AS channel,
        cr.cr_return_quantity AS quantity,
        cr.cr_return_amount AS return_amount,
        cr.cr_net_loss AS net_loss
    FROM catalog_returns cr
    JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
    WHERE d.d_date >= date_add('year', -2, DATE '2024-10-01')
    UNION ALL
    SELECT
        sr.sr_item_sk,
        sr.sr_returned_date_sk,
        d.d_date,
        date_trunc('month', d.d_date),
        'store',
        sr.sr_return_quantity,
        sr.sr_return_amt,
        sr.sr_net_loss
    FROM store_returns sr
    JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
    WHERE d.d_date >= date_add('year', -2, DATE '2024-10-01')
    UNION ALL
    SELECT
        wr.wr_item_sk,
        wr.wr_returned_date_sk,
        d.d_date,
        date_trunc('month', d.d_date),
        'web',
        wr.wr_return_quantity,
        wr.wr_return_amt,
        wr.wr_net_loss
    FROM web_returns wr
    JOIN date_dim d ON wr.wr_returned_date_sk = d.d_date_sk
    WHERE d.d_date >= date_add('year', -2, DATE '2024-10-01')
),
sales_agg AS (
    SELECT
        s.channel,
        s.item_sk,
        i.i_product_name,
        i.i_category,
        i.i_brand,
        s.month_start,
        SUM(s.quantity) AS total_quantity_sold,
        SUM(s.sales_amount) AS total_sales_amount,
        SUM(s.net_profit) AS total_net_profit,
        AVG(CASE WHEN s.sales_amount = 0 THEN 0 ELSE s.discount_amount / s.sales_amount END) AS avg_discount_ratio
    FROM sales s
    JOIN item i ON s.item_sk = i.i_item_sk
    GROUP BY s.channel, s.item_sk, i.i_product_name, i.i_category, i.i_brand, s.month_start
),
returns_agg AS (
    SELECT
        r.channel,
        r.item_sk,
        r.month_start,
        SUM(r.quantity) AS total_quantity_returned,
        SUM(r.return_amount) AS total_return_amount,
        SUM(r.net_loss) AS total_return_loss
    FROM returns r
    GROUP BY r.channel, r.item_sk, r.month_start
),
combined AS (
    SELECT
        sa.channel,
        sa.item_sk,
        sa.i_product_name,
        sa.i_category,
        sa.i_brand,
        sa.month_start,
        sa.total_quantity_sold,
        sa.total_sales_amount,
        sa.total_net_profit,
        sa.avg_discount_ratio,
        COALESCE(ra.total_quantity_returned, 0) AS total_quantity_returned,
        COALESCE(ra.total_return_amount, 0) AS total_return_amount,
        COALESCE(ra.total_return_loss, 0) AS total_return_loss,
        (sa.total_net_profit - COALESCE(ra.total_return_loss, 0)) AS net_profit_adj
    FROM sales_agg sa
    LEFT JOIN returns_agg ra ON sa.channel = ra.channel AND sa.item_sk = ra.item_sk AND sa.month_start = ra.month_start
),
ranked AS (
    SELECT
        channel,
        month_start,
        i_category,
        i_brand,
        i_product_name,
        total_quantity_sold,
        total_sales_amount,
        total_net_profit,
        avg_discount_ratio,
        total_quantity_returned,
        total_return_amount,
        total_return_loss,
        net_profit_adj,
        RANK() OVER (PARTITION BY channel, month_start ORDER BY net_profit_adj DESC) AS profit_rank
    FROM combined
)
SELECT
    channel,
    month_start,
    i_category,
    i_brand,
    i_product_name,
    total_quantity_sold,
    total_sales_amount,
    total_net_profit,
    avg_discount_ratio,
    total_quantity_returned,
    total_return_amount,
    total_return_loss,
    net_profit_adj,
    profit_rank,
    AVG(net_profit_adj) OVER (PARTITION BY channel, i_category, i_brand ORDER BY month_start ROWS BETWEEN 2 PRECEDING AND CURRENT ROW) AS three_month_moving_avg_net_profit
FROM ranked
WHERE profit_rank <= 10
ORDER BY channel, month_start DESC, profit_rank
LIMIT 200

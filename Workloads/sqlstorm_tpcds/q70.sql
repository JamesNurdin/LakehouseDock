WITH sales_by_channel AS (
    SELECT ss.ss_sold_date_sk AS date_sk,
           ss.ss_item_sk AS item_sk,
           ss.ss_ticket_number AS order_num,
           ss.ss_quantity AS quantity,
           ss.ss_net_paid AS net_paid,
           'store' AS channel
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    WHERE d.d_year = 2001
    UNION ALL
    SELECT ws.ws_sold_date_sk,
           ws.ws_item_sk,
           ws.ws_order_number,
           ws.ws_quantity,
           ws.ws_net_paid,
           'web'
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE d.d_year = 2001
    UNION ALL
    SELECT cs.cs_sold_date_sk,
           cs.cs_item_sk,
           cs.cs_order_number,
           cs.cs_quantity,
           cs.cs_net_paid,
           'catalog'
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    WHERE d.d_year = 2001
),
returns_by_channel AS (
    SELECT sr.sr_returned_date_sk AS date_sk,
           sr.sr_item_sk AS item_sk,
           sr.sr_ticket_number AS order_num,
           sr.sr_return_quantity AS quantity,
           sr.sr_net_loss AS net_loss,
           'store' AS channel
    FROM store_returns sr
    JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
    WHERE d.d_year = 2001
    UNION ALL
    SELECT wr.wr_returned_date_sk,
           wr.wr_item_sk,
           wr.wr_order_number,
           wr.wr_return_quantity,
           wr.wr_net_loss,
           'web'
    FROM web_returns wr
    JOIN date_dim d ON wr.wr_returned_date_sk = d.d_date_sk
    WHERE d.d_year = 2001
    UNION ALL
    SELECT cr.cr_returned_date_sk,
           cr.cr_item_sk,
           cr.cr_order_number,
           cr.cr_return_quantity,
           cr.cr_net_loss,
           'catalog'
    FROM catalog_returns cr
    JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
    WHERE d.d_year = 2001
),
sales_agg AS (
    SELECT
        channel,
        date_sk,
        item_sk,
        COUNT(DISTINCT order_num) AS orders,
        SUM(quantity) AS total_qty,
        SUM(net_paid) AS total_paid,
        COUNT(*) FILTER (WHERE quantity IS NULL) AS null_qty_rows,
        MAX(quantity) AS max_qty,
        MIN(quantity) AS min_qty
    FROM sales_by_channel
    GROUP BY channel, date_sk, item_sk
),
returns_agg AS (
    SELECT
        channel,
        date_sk,
        item_sk,
        COUNT(DISTINCT order_num) AS return_orders,
        SUM(quantity) AS return_qty,
        SUM(net_loss) AS total_loss
    FROM returns_by_channel
    GROUP BY channel, date_sk, item_sk
),
final_combined AS (
    SELECT
        COALESCE(s.channel, r.channel) AS channel,
        COALESCE(s.date_sk, r.date_sk) AS date_sk,
        COALESCE(s.item_sk, r.item_sk) AS item_sk,
        COALESCE(s.orders, 0) - COALESCE(r.return_orders, 0) AS net_orders,
        COALESCE(s.total_qty, 0) - COALESCE(r.return_qty, 0) AS net_quantity,
        COALESCE(s.total_paid, 0) - COALESCE(r.total_loss, 0) AS net_amount,
        CASE 
            WHEN COALESCE(s.total_paid, 0) = 0 THEN NULL
            ELSE ROUND((COALESCE(s.total_paid, 0) - COALESCE(r.total_loss, 0)) / NULLIF(COALESCE(s.total_paid, 0), 0), 2)
        END AS profit_margin,
        (SELECT MIN(d.d_date) FROM date_dim d WHERE d.d_date_sk = COALESCE(s.date_sk, r.date_sk)) AS sale_date,
        SUM(COALESCE(s.total_qty, 0) - COALESCE(r.return_qty, 0)) OVER (
            PARTITION BY COALESCE(s.channel, r.channel)
            ORDER BY COALESCE(s.date_sk, r.date_sk)
            ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
        ) AS running_net_qty,
        concat(
            COALESCE(s.channel, r.channel),
            ':',
            date_format(
                date_add('day', COALESCE(s.date_sk, r.date_sk), date '1970-01-01'),
                '%Y-%m-%d'
            )
        ) AS channel_date_key,
        CASE 
            WHEN COALESCE(s.null_qty_rows, 0) > 0 AND s.max_qty IS NULL THEN 'ANOMALY'
            ELSE 'OK'
        END AS qty_status,
        ROW_NUMBER() OVER (
            PARTITION BY COALESCE(s.channel, r.channel), COALESCE(s.item_sk, r.item_sk)
            ORDER BY COALESCE(s.date_sk, r.date_sk) DESC
        ) AS rn
    FROM sales_agg s
    FULL OUTER JOIN returns_agg r
        ON s.channel = r.channel
        AND s.date_sk = r.date_sk
        AND s.item_sk = r.item_sk
)
(
SELECT
    channel,
    date_sk,
    item_sk,
    net_orders,
    net_quantity,
    net_amount,
    profit_margin,
    sale_date,
    running_net_qty,
    channel_date_key,
    qty_status
FROM final_combined
WHERE rn = 1 AND net_amount IS NOT NULL

UNION ALL

SELECT
    channel,
    date_sk,
    item_sk,
    net_orders,
    net_quantity,
    net_amount,
    profit_margin,
    sale_date,
    running_net_qty,
    channel_date_key,
    qty_status
FROM final_combined
WHERE rn = 1 AND net_amount IS NULL
)
EXCEPT
SELECT
    channel,
    date_sk,
    item_sk,
    net_orders,
    net_quantity,
    net_amount,
    profit_margin,
    sale_date,
    running_net_qty,
    channel_date_key,
    qty_status
FROM final_combined
WHERE rn = 1 AND net_quantity < 0
ORDER BY channel, date_sk DESC, item_sk
LIMIT 200

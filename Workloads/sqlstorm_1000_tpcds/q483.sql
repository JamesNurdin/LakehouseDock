WITH sales AS (
    SELECT cs.cs_sold_date_sk AS date_sk,
           cs.cs_item_sk AS item_sk,
           cs.cs_net_profit AS net_profit,
           cs.cs_net_paid AS net_paid,
           cs.cs_quantity AS quantity,
           'catalog' AS channel,
           cs.cs_promo_sk AS promo_sk,
           cs.cs_call_center_sk AS call_center_sk,
           NULL AS store_sk,
           NULL AS web_page_sk
    FROM catalog_sales cs
    UNION ALL
    SELECT ss.ss_sold_date_sk,
           ss.ss_item_sk,
           ss.ss_net_profit,
           ss.ss_net_paid,
           ss.ss_quantity,
           'store',
           ss.ss_promo_sk,
           NULL,
           ss.ss_store_sk,
           NULL
    FROM store_sales ss
    UNION ALL
    SELECT ws.ws_sold_date_sk,
           ws.ws_item_sk,
           ws.ws_net_profit,
           ws.ws_net_paid,
           ws.ws_quantity,
           'web',
           ws.ws_promo_sk,
           NULL,
           NULL,
           ws.ws_web_page_sk
    FROM web_sales ws
),
returns AS (
    SELECT cr.cr_returned_date_sk AS date_sk,
           cr.cr_item_sk AS item_sk,
           cr.cr_net_loss AS net_loss,
           cr.cr_return_quantity AS quantity,
           'catalog' AS channel
    FROM catalog_returns cr
    UNION ALL
    SELECT sr.sr_returned_date_sk,
           sr.sr_item_sk,
           sr.sr_net_loss,
           sr.sr_return_quantity,
           'store'
    FROM store_returns sr
    UNION ALL
    SELECT wr.wr_returned_date_sk,
           wr.wr_item_sk,
           wr.wr_net_loss,
           wr.wr_return_quantity,
           'web'
    FROM web_returns wr
),
sales_agg AS (
    SELECT d.d_year,
           d.d_month_seq AS month_seq,
           i.i_category,
           s.channel,
           SUM(s.net_profit) AS total_profit,
           SUM(s.net_paid) AS total_sales,
           SUM(s.quantity) AS total_quantity,
           COUNT(*) AS sales_transactions,
           SUM(COALESCE(p.p_cost, 0)) AS total_promo_cost
    FROM sales s
    JOIN date_dim d ON s.date_sk = d.d_date_sk
    JOIN item i ON s.item_sk = i.i_item_sk
    LEFT JOIN promotion p ON s.promo_sk = p.p_promo_sk
    GROUP BY d.d_year, d.d_month_seq, i.i_category, s.channel
),
returns_agg AS (
    SELECT d.d_year,
           d.d_month_seq AS month_seq,
           i.i_category,
           r.channel,
           SUM(r.net_loss) AS total_loss,
           SUM(r.quantity) AS total_return_quantity,
           COUNT(*) AS return_transactions
    FROM returns r
    JOIN date_dim d ON r.date_sk = d.d_date_sk
    JOIN item i ON r.item_sk = i.i_item_sk
    GROUP BY d.d_year, d.d_month_seq, i.i_category, r.channel
),
combined AS (
    SELECT
        COALESCE(sa.d_year, ra.d_year) AS year,
        COALESCE(sa.month_seq, ra.month_seq) AS month_seq,
        COALESCE(sa.i_category, ra.i_category) AS category,
        COALESCE(sa.channel, ra.channel) AS channel,
        COALESCE(sa.total_profit, 0) AS total_profit,
        COALESCE(sa.total_sales, 0) AS total_sales,
        COALESCE(sa.total_quantity, 0) AS total_quantity,
        COALESCE(sa.sales_transactions, 0) AS sales_transactions,
        COALESCE(ra.total_loss, 0) AS total_loss,
        COALESCE(ra.total_return_quantity, 0) AS total_return_quantity,
        COALESCE(ra.return_transactions, 0) AS return_transactions,
        COALESCE(sa.total_promo_cost, 0) AS total_promo_cost,
        (COALESCE(sa.total_profit, 0) - COALESCE(ra.total_loss, 0) - COALESCE(sa.total_promo_cost, 0)) AS net_profit_adjusted
    FROM sales_agg sa
    FULL OUTER JOIN returns_agg ra
      ON sa.d_year = ra.d_year
     AND sa.month_seq = ra.month_seq
     AND sa.i_category = ra.i_category
     AND sa.channel = ra.channel
)
SELECT
    year,
    month_seq,
    category,
    channel,
    total_profit,
    total_loss,
    total_promo_cost,
    net_profit_adjusted,
    total_sales,
    total_quantity,
    total_return_quantity,
    sales_transactions,
    return_transactions,
    RANK() OVER (PARTITION BY year, month_seq ORDER BY net_profit_adjusted DESC) AS profit_rank,
    SUM(net_profit_adjusted) OVER (PARTITION BY year ORDER BY month_seq ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS cumulative_year_profit,
    net_profit_adjusted - LAG(net_profit_adjusted) OVER (PARTITION BY category, channel ORDER BY year, month_seq) AS profit_change_prev_month
FROM combined
WHERE year BETWEEN 1999 AND 2002
ORDER BY year, month_seq, profit_rank
LIMIT 100

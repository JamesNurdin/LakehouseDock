WITH sales AS (
    SELECT cs.cs_sold_date_sk AS date_sk,
           cs.cs_item_sk AS item_sk,
           'catalog' AS channel,
           cs.cs_quantity AS quantity,
           cs.cs_net_paid AS net_paid,
           cs.cs_net_profit AS net_profit,
           cs.cs_promo_sk AS promo_sk,
           cs.cs_call_center_sk AS call_center_sk,
           cs.cs_warehouse_sk AS warehouse_sk,
           NULL AS store_sk,
           NULL AS web_page_sk
    FROM catalog_sales cs
    WHERE cs.cs_sold_date_sk BETWEEN 2451910 AND 2452284
    UNION ALL
    SELECT ss.ss_sold_date_sk,
           ss.ss_item_sk,
           'store',
           ss.ss_quantity,
           ss.ss_net_paid,
           ss.ss_net_profit,
           ss.ss_promo_sk,
           NULL,
           NULL,
           ss.ss_store_sk,
           NULL
    FROM store_sales ss
    WHERE ss.ss_sold_date_sk BETWEEN 2451910 AND 2452284
    UNION ALL
    SELECT ws.ws_sold_date_sk,
           ws.ws_item_sk,
           'web',
           ws.ws_quantity,
           ws.ws_net_paid,
           ws.ws_net_profit,
           ws.ws_promo_sk,
           NULL,
           NULL,
           NULL,
           ws.ws_web_page_sk
    FROM web_sales ws
    WHERE ws.ws_sold_date_sk BETWEEN 2451910 AND 2452284
),
returns AS (
    SELECT cr.cr_returned_date_sk AS date_sk,
           cr.cr_item_sk AS item_sk,
           'catalog' AS channel,
           cr.cr_return_quantity AS quantity,
           cr.cr_return_amount AS return_amount,
           cr.cr_net_loss AS net_loss
    FROM catalog_returns cr
    WHERE cr.cr_returned_date_sk BETWEEN 2451910 AND 2452284
    UNION ALL
    SELECT sr.sr_returned_date_sk,
           sr.sr_item_sk,
           'store',
           sr.sr_return_quantity,
           sr.sr_return_amt,
           sr.sr_net_loss
    FROM store_returns sr
    WHERE sr.sr_returned_date_sk BETWEEN 2451910 AND 2452284
    UNION ALL
    SELECT wr.wr_returned_date_sk,
           wr.wr_item_sk,
           'web',
           wr.wr_return_quantity,
           wr.wr_return_amt,
           wr.wr_net_loss
    FROM web_returns wr
    WHERE wr.wr_returned_date_sk BETWEEN 2451910 AND 2452284
),
sales_agg AS (
    SELECT s.date_sk,
           s.item_sk,
           s.channel,
           SUM(s.quantity) AS total_quantity,
           SUM(s.net_paid) AS total_net_paid,
           SUM(s.net_profit) AS total_net_profit
    FROM sales s
    GROUP BY s.date_sk, s.item_sk, s.channel
),
returns_agg AS (
    SELECT r.date_sk,
           r.item_sk,
           r.channel,
           SUM(r.quantity) AS total_return_quantity,
           SUM(r.return_amount) AS total_return_amount,
           SUM(r.net_loss) AS total_return_loss
    FROM returns r
    GROUP BY r.date_sk, r.item_sk, r.channel
),
joined AS (
    SELECT d.d_year,
           d.d_moy AS month,
           i.i_category,
           i.i_brand,
           i.i_class,
           sa.channel,
           COALESCE(sa.total_quantity, 0) AS sales_qty,
           COALESCE(sa.total_net_paid, 0) AS sales_net_paid,
           COALESCE(sa.total_net_profit, 0) AS sales_net_profit,
           COALESCE(ra.total_return_quantity, 0) AS return_qty,
           COALESCE(ra.total_return_amount, 0) AS return_amount,
           COALESCE(ra.total_return_loss, 0) AS return_loss
    FROM date_dim d
    JOIN sales_agg sa ON sa.date_sk = d.d_date_sk
    LEFT JOIN returns_agg ra ON ra.date_sk = d.d_date_sk
                             AND ra.item_sk = sa.item_sk
                             AND ra.channel = sa.channel
    JOIN item i ON i.i_item_sk = sa.item_sk
    WHERE d.d_year BETWEEN 2000 AND 2005
),
agg AS (
    SELECT
        j.d_year,
        j.month,
        j.i_category,
        j.i_brand,
        j.i_class,
        j.channel,
        SUM(j.sales_qty) AS sum_sales_qty,
        SUM(j.sales_net_paid) AS sum_sales_net_paid,
        SUM(j.sales_net_profit) AS sum_sales_net_profit,
        SUM(j.return_qty) AS sum_return_qty,
        SUM(j.return_amount) AS sum_return_amount,
        ROUND(SUM(j.sales_net_paid) - SUM(j.return_amount), 2) AS net_revenue
    FROM joined j
    GROUP BY
        j.d_year,
        j.month,
        j.i_category,
        j.i_brand,
        j.i_class,
        j.channel
    HAVING SUM(j.sales_net_paid) > 0
),
ranked AS (
    SELECT
        a.*,
        ROW_NUMBER() OVER (PARTITION BY a.d_year ORDER BY a.net_revenue DESC) AS revenue_rank
    FROM agg a
)
SELECT
    d_year,
    month,
    i_category,
    i_brand,
    i_class,
    channel,
    sum_sales_qty,
    sum_sales_net_paid,
    sum_sales_net_profit,
    sum_return_qty,
    sum_return_amount,
    net_revenue,
    revenue_rank
FROM ranked
WHERE revenue_rank <= 10
ORDER BY d_year, net_revenue DESC
LIMIT 100

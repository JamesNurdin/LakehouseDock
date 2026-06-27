WITH sales_agg AS (
    SELECT
        s.s_store_name AS store_name,
        d.d_year AS year,
        d.d_month_seq AS month_seq,
        i.i_category AS category,
        SUM(ss.ss_quantity) AS total_sales_quantity,
        SUM(ss.ss_net_profit) AS total_sales_net_profit,
        SUM(ss.ss_ext_discount_amt) AS total_sales_discount_amt
    FROM store_sales ss
    JOIN date_dim d
        ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN store s
        ON ss.ss_store_sk = s.s_store_sk
    JOIN item i
        ON ss.ss_item_sk = i.i_item_sk
    WHERE d.d_year = 2001
    GROUP BY s.s_store_name, d.d_year, d.d_month_seq, i.i_category
),
returns_agg AS (
    SELECT
        s.s_store_name AS store_name,
        d.d_year AS year,
        d.d_month_seq AS month_seq,
        i.i_category AS category,
        SUM(sr.sr_return_quantity) AS total_return_quantity,
        SUM(sr.sr_net_loss) AS total_return_net_loss
    FROM store_returns sr
    JOIN store_sales ss
        ON sr.sr_ticket_number = ss.ss_ticket_number
        AND sr.sr_item_sk = ss.ss_item_sk
    JOIN date_dim d
        ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN store s
        ON ss.ss_store_sk = s.s_store_sk
    JOIN item i
        ON ss.ss_item_sk = i.i_item_sk
    WHERE d.d_year = 2001
    GROUP BY s.s_store_name, d.d_year, d.d_month_seq, i.i_category
)
SELECT
    sa.store_name,
    sa.year,
    sa.month_seq,
    sa.category,
    sa.total_sales_quantity,
    sa.total_sales_net_profit,
    COALESCE(ra.total_return_quantity, 0) AS total_return_quantity,
    COALESCE(ra.total_return_net_loss, 0) AS total_return_net_loss,
    CASE WHEN sa.total_sales_quantity = 0 THEN 0
         ELSE COALESCE(ra.total_return_quantity, 0) / sa.total_sales_quantity END AS return_rate,
    CASE WHEN sa.total_sales_quantity = 0 THEN 0
         ELSE sa.total_sales_discount_amt / sa.total_sales_quantity END AS avg_discount_per_item,
    (sa.total_sales_net_profit - COALESCE(ra.total_return_net_loss, 0)) AS net_profit_after_returns
FROM sales_agg sa
LEFT JOIN returns_agg ra
    ON sa.store_name = ra.store_name
    AND sa.year = ra.year
    AND sa.month_seq = ra.month_seq
    AND sa.category = ra.category
ORDER BY net_profit_after_returns DESC
LIMIT 10

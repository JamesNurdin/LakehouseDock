WITH sales_summary AS (
    SELECT
        s.s_store_id,
        s.s_store_name,
        d.d_year,
        d.d_month_seq,
        SUM(ss.ss_net_paid) AS store_sales_net_paid,
        SUM(ss.ss_net_profit) AS store_sales_net_profit,
        SUM(cs.cs_net_paid) AS catalog_sales_net_paid,
        SUM(cs.cs_net_profit) AS catalog_sales_net_profit,
        SUM(cr.cr_net_loss) AS returns_net_loss
    FROM store_sales ss
    JOIN store s
        ON ss.ss_store_sk = s.s_store_sk
    JOIN date_dim d
        ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN catalog_sales cs
        ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN catalog_returns cr
        ON cr.cr_item_sk = cs.cs_item_sk
       AND cr.cr_order_number = cs.cs_order_number
    JOIN date_dim d_return
        ON cr.cr_returned_date_sk = d_return.d_date_sk
    JOIN date_dim d_closed
        ON s.s_closed_date_sk = d_closed.d_date_sk
    GROUP BY s.s_store_id, s.s_store_name, d.d_year, d.d_month_seq
)
SELECT
    s_store_id,
    s_store_name,
    d_year,
    d_month_seq,
    store_sales_net_paid,
    catalog_sales_net_paid,
    returns_net_loss,
    (store_sales_net_profit + catalog_sales_net_profit - returns_net_loss) AS total_profit,
    RANK() OVER (PARTITION BY d_year ORDER BY (store_sales_net_profit + catalog_sales_net_profit - returns_net_loss) DESC) AS profit_rank
FROM sales_summary
ORDER BY d_year, total_profit DESC
LIMIT 100

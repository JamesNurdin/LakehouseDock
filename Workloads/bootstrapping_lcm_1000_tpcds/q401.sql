WITH agg AS (
    SELECT
        s.s_store_id AS store_id,
        s.s_store_name AS store_name,
        d_sales.d_date AS sales_date,
        d_sales.d_year AS sales_year,
        d_sales.d_month_seq AS sales_month_seq,
        d_closed.d_current_day AS store_closed_day,
        d_return.d_current_month AS return_month,
        w.w_warehouse_name AS warehouse_name,
        SUM(ss.ss_net_profit) AS total_sales_profit,
        SUM(ss.ss_ext_discount_amt) AS total_discount,
        SUM(cr.cr_net_loss) AS total_return_loss,
        COUNT(cr.cr_return_quantity) AS total_return_quantity,
        COUNT(DISTINCT ss.ss_ticket_number) AS distinct_tickets
    FROM store_sales ss
    JOIN date_dim d_sales
        ON ss.ss_sold_date_sk = d_sales.d_date_sk
    JOIN store s
        ON ss.ss_store_sk = s.s_store_sk
    JOIN date_dim d_closed
        ON s.s_closed_date_sk = d_closed.d_date_sk
    JOIN catalog_returns cr
        ON cr.cr_returned_date_sk = d_sales.d_date_sk
    JOIN date_dim d_return
        ON cr.cr_returned_date_sk = d_return.d_date_sk
    JOIN warehouse w
        ON cr.cr_warehouse_sk = w.w_warehouse_sk
    GROUP BY
        s.s_store_id,
        s.s_store_name,
        d_sales.d_date,
        d_sales.d_year,
        d_sales.d_month_seq,
        d_closed.d_current_day,
        d_return.d_current_month,
        w.w_warehouse_name
)
SELECT
    store_id,
    store_name,
    sales_date,
    sales_year,
    sales_month_seq,
    store_closed_day,
    return_month,
    warehouse_name,
    total_sales_profit,
    total_discount,
    total_return_loss,
    total_return_quantity,
    distinct_tickets,
    ROUND((total_return_loss / NULLIF(total_sales_profit, 0)) * 100, 2) AS loss_to_profit_pct,
    ROW_NUMBER() OVER (PARTITION BY store_id ORDER BY total_sales_profit DESC) AS sales_rank
FROM agg
ORDER BY total_sales_profit DESC
LIMIT 100

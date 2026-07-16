WITH sales_return_agg AS (
    SELECT
        s.s_store_id,
        s.s_city,
        s.s_state,
        d_sale.d_year AS sale_year,
        d_sale.d_month_seq AS sale_month_seq,
        d_closed.d_year AS store_closed_year,
        c.c_first_name AS c_first_name,
        c.c_last_name AS c_last_name,
        d_cust_first_sale.d_year AS customer_first_sale_year,
        COUNT(DISTINCT ss.ss_ticket_number) AS total_tickets,
        SUM(ss.ss_net_profit) AS total_net_profit,
        SUM(COALESCE(cr.cr_net_loss, 0)) AS total_net_loss,
        SUM(ss.ss_quantity) AS total_quantity_sold,
        SUM(COALESCE(cr.cr_return_quantity, 0)) AS total_quantity_returned
    FROM store_sales ss
    JOIN date_dim d_sale
        ON ss.ss_sold_date_sk = d_sale.d_date_sk
    JOIN store s
        ON ss.ss_store_sk = s.s_store_sk
    JOIN date_dim d_closed
        ON s.s_closed_date_sk = d_closed.d_date_sk
    JOIN customer c
        ON ss.ss_customer_sk = c.c_customer_sk
    JOIN date_dim d_cust_first_sale
        ON c.c_first_sales_date_sk = d_cust_first_sale.d_date_sk
    LEFT JOIN catalog_returns cr
        ON cr.cr_returned_date_sk = d_sale.d_date_sk
        AND cr.cr_refunded_customer_sk = c.c_customer_sk
    GROUP BY
        s.s_store_id,
        s.s_city,
        s.s_state,
        d_sale.d_year,
        d_sale.d_month_seq,
        d_closed.d_year,
        c.c_first_name,
        c.c_last_name,
        d_cust_first_sale.d_year
)
SELECT
    s_store_id,
    s_city,
    s_state,
    sale_year,
    sale_month_seq,
    store_closed_year,
    c_first_name,
    c_last_name,
    customer_first_sale_year,
    total_tickets,
    total_net_profit,
    total_net_loss,
    total_quantity_sold,
    total_quantity_returned,
    CASE
        WHEN total_net_loss > 0 THEN ROUND(total_net_profit / total_net_loss, 2)
    END AS profit_to_loss_ratio,
    RANK() OVER (PARTITION BY s_store_id ORDER BY total_net_profit DESC) AS profit_rank_per_store
FROM sales_return_agg
ORDER BY profit_to_loss_ratio DESC NULLS LAST
LIMIT 100

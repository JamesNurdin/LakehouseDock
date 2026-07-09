WITH monthly_warehouse_metrics AS (
    SELECT
        d.d_year,
        d.d_moy,
        w.w_warehouse_name,
        SUM(COALESCE(cr.cr_net_loss, 0)) AS total_return_net_loss,
        SUM(COALESCE(ss.ss_net_profit, 0)) AS total_sales_net_profit,
        COUNT(DISTINCT cr.cr_order_number) AS distinct_return_orders,
        COUNT(DISTINCT ss.ss_ticket_number) AS distinct_sales_tickets,
        AVG(ss.ss_ext_discount_amt) AS avg_sales_discount,
        AVG(wp.wp_link_count) AS avg_page_links
    FROM date_dim d
    JOIN catalog_returns cr
        ON cr.cr_returned_date_sk = d.d_date_sk
    JOIN warehouse w
        ON cr.cr_warehouse_sk = w.w_warehouse_sk
    LEFT JOIN store_sales ss
        ON ss.ss_sold_date_sk = d.d_date_sk
    LEFT JOIN web_page wp
        ON wp.wp_access_date_sk = d.d_date_sk
    WHERE d.d_year = 2001
      AND w.w_state = 'CA'
    GROUP BY d.d_year, d.d_moy, w.w_warehouse_name
)
SELECT
    d_year,
    d_moy,
    w_warehouse_name,
    total_return_net_loss,
    total_sales_net_profit,
    distinct_return_orders,
    distinct_sales_tickets,
    avg_sales_discount,
    avg_page_links,
    RANK() OVER (PARTITION BY d_year, d_moy ORDER BY total_return_net_loss DESC) AS warehouse_rank
FROM monthly_warehouse_metrics
WHERE total_return_net_loss > 0
ORDER BY d_year, d_moy, warehouse_rank
LIMIT 20

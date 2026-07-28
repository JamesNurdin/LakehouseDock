WITH sales_agg AS (
    SELECT
        c.c_customer_sk,
        c.c_customer_id,
        SUM(cs.cs_net_paid_inc_tax) AS total_catalog_net_paid,
        SUM(ss.ss_net_paid_inc_tax) AS total_store_net_paid,
        SUM(cs.cs_net_profit) AS total_catalog_profit,
        SUM(ss.ss_net_profit) AS total_store_profit,
        SUM(sr.sr_net_loss) AS total_return_loss,
        COUNT(DISTINCT cs.cs_order_number) AS catalog_orders,
        COUNT(DISTINCT ss.ss_ticket_number) AS store_tickets
    FROM catalog_sales cs
    JOIN time_dim td ON cs.cs_sold_time_sk = td.t_time_sk
    JOIN customer c ON cs.cs_bill_customer_sk = c.c_customer_sk
    JOIN household_demographics hd ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
    JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
    JOIN store_sales ss ON ss.ss_customer_sk = c.c_customer_sk
    JOIN store_returns sr ON sr.sr_customer_sk = c.c_customer_sk
                        AND sr.sr_ticket_number = ss.ss_ticket_number
    JOIN web_page wp ON wp.wp_customer_sk = c.c_customer_sk
    JOIN web_returns wr ON wr.wr_refunded_customer_sk = c.c_customer_sk
                         AND wr.wr_web_page_sk = wp.wp_web_page_sk
    WHERE
        td.t_sub_shift = 'morning'
        AND td.t_second > 10
        AND ss.ss_quantity > 1
        AND sr.sr_return_amt > 500
        AND cs.cs_net_paid_inc_tax > 1000
        AND hd.hd_vehicle_count >= 2
        AND w.w_state = 'CA'
        AND wp.wp_type = 'product'
        AND wr.wr_fee < 50
    GROUP BY c.c_customer_sk, c.c_customer_id
)
SELECT
    AVG(total_catalog_net_paid) AS avg_catalog_net_paid,
    AVG(total_store_net_paid) AS avg_store_net_paid,
    AVG(total_return_loss) AS avg_return_loss,
    COUNT(*) AS qualifying_customers
FROM sales_agg
WHERE total_return_loss > 1000
HAVING COUNT(*) > 10

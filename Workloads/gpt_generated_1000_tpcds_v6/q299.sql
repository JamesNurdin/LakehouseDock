WITH customer_agg AS (
    SELECT
        c.c_customer_id,
        d.d_year,
        SUM(ss.ss_net_paid) AS store_sales_total,
        SUM(sr.sr_net_loss) AS store_returns_loss,
        SUM(cs.cs_net_paid) AS catalog_sales_total,
        SUM(cr.cr_net_loss) AS catalog_returns_loss,
        SUM(ws.ws_net_paid) AS web_sales_total,
        SUM(wr.wr_net_loss) AS web_returns_loss,
        SUM(i.inv_quantity_on_hand) AS total_inventory_qty
    FROM
        customer c
        JOIN store_sales ss
            ON ss.ss_customer_sk = c.c_customer_sk
        JOIN store_returns sr
            ON sr.sr_customer_sk = c.c_customer_sk
           AND sr.sr_item_sk = ss.ss_item_sk
           AND sr.sr_ticket_number = ss.ss_ticket_number
        JOIN catalog_sales cs
            ON cs.cs_bill_customer_sk = c.c_customer_sk
        JOIN catalog_returns cr
            ON cr.cr_refunded_customer_sk = c.c_customer_sk
           AND cr.cr_item_sk = cs.cs_item_sk
           AND cr.cr_order_number = cs.cs_order_number
        JOIN web_sales ws
            ON ws.ws_bill_customer_sk = c.c_customer_sk
        JOIN web_returns wr
            ON wr.wr_refunded_customer_sk = c.c_customer_sk
           AND wr.wr_item_sk = ws.ws_item_sk
           AND wr.wr_order_number = ws.ws_order_number
        JOIN warehouse w
            ON w.w_warehouse_sk = cs.cs_warehouse_sk
        JOIN inventory i
            ON i.inv_warehouse_sk = w.w_warehouse_sk
           AND i.inv_date_sk = ss.ss_sold_date_sk
        JOIN date_dim d
            ON d.d_date_sk = ss.ss_sold_date_sk
        JOIN time_dim t
            ON t.t_time_sk = ss.ss_sold_time_sk
    WHERE
        d.d_year = 2001
        AND d.d_month_seq BETWEEN 1 AND 12
        AND w.w_state = 'CA'
        AND c.c_preferred_cust_flag = 'Y'
        AND i.inv_quantity_on_hand > 0
    GROUP BY
        c.c_customer_id,
        d.d_year
)
SELECT
    ca.c_customer_id,
    ca.d_year,
    ca.store_sales_total,
    ca.catalog_sales_total,
    ca.web_sales_total,
    (ca.store_sales_total - ca.store_returns_loss
     + ca.catalog_sales_total - ca.catalog_returns_loss
     + ca.web_sales_total - ca.web_returns_loss) AS total_net_profit,
    RANK() OVER (ORDER BY (ca.store_sales_total - ca.store_returns_loss
                           + ca.catalog_sales_total - ca.catalog_returns_loss
                           + ca.web_sales_total - ca.web_returns_loss) DESC) AS profit_rank
FROM
    customer_agg ca
WHERE
    (ca.store_sales_total - ca.store_returns_loss
     + ca.catalog_sales_total - ca.catalog_returns_loss
     + ca.web_sales_total - ca.web_returns_loss) > (
        SELECT AVG(sub.total_net_profit)
        FROM (
            SELECT
                (store_sales_total - store_returns_loss
                 + catalog_sales_total - catalog_returns_loss
                 + web_sales_total - web_returns_loss) AS total_net_profit
            FROM customer_agg
        ) sub
    )
ORDER BY total_net_profit DESC
LIMIT 100

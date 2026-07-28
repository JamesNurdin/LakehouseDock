WITH agg AS (
    SELECT
        d_cs.d_year AS d_year,
        i.i_category AS i_category,
        SUM(cs.cs_net_paid) AS catalog_sales_net,
        SUM(ss.ss_net_paid) AS store_sales_net,
        SUM(ws.ws_net_paid) AS web_sales_net,
        SUM(cr.cr_net_loss) AS catalog_returns_loss,
        SUM(sr.sr_net_loss) AS store_returns_loss,
        SUM(wr.wr_net_loss) AS web_returns_loss,
        (
            SUM(cs.cs_net_paid) +
            SUM(ss.ss_net_paid) +
            SUM(ws.ws_net_paid) -
            COALESCE(SUM(cr.cr_net_loss), 0) -
            COALESCE(SUM(sr.sr_net_loss), 0) -
            COALESCE(SUM(wr.wr_net_loss), 0)
        ) AS net_revenue
    FROM
        catalog_sales cs
        JOIN date_dim d_cs ON cs.cs_sold_date_sk = d_cs.d_date_sk
        JOIN item i ON cs.cs_item_sk = i.i_item_sk
        JOIN customer c_bill ON cs.cs_bill_customer_sk = c_bill.c_customer_sk
        JOIN household_demographics hd_bill ON cs.cs_bill_hdemo_sk = hd_bill.hd_demo_sk
        LEFT JOIN catalog_returns cr ON cs.cs_order_number = cr.cr_order_number
        LEFT JOIN date_dim d_cr ON cr.cr_returned_date_sk = d_cr.d_date_sk
        LEFT JOIN customer c_refund ON cr.cr_refunded_customer_sk = c_refund.c_customer_sk
        LEFT JOIN household_demographics hd_refund ON cr.cr_refunded_hdemo_sk = hd_refund.hd_demo_sk
        JOIN store_sales ss ON ss.ss_item_sk = i.i_item_sk
        JOIN date_dim d_ss ON ss.ss_sold_date_sk = d_ss.d_date_sk
        JOIN customer c_store ON ss.ss_customer_sk = c_store.c_customer_sk
        JOIN household_demographics hd_store ON ss.ss_hdemo_sk = hd_store.hd_demo_sk
        LEFT JOIN store_returns sr ON sr.sr_ticket_number = ss.ss_ticket_number AND sr.sr_item_sk = i.i_item_sk
        LEFT JOIN date_dim d_sr ON sr.sr_returned_date_sk = d_sr.d_date_sk
        LEFT JOIN customer c_sr_refund ON sr.sr_customer_sk = c_sr_refund.c_customer_sk
        LEFT JOIN household_demographics hd_sr ON sr.sr_hdemo_sk = hd_sr.hd_demo_sk
        JOIN web_sales ws ON ws.ws_item_sk = i.i_item_sk
        JOIN date_dim d_ws ON ws.ws_sold_date_sk = d_ws.d_date_sk
        JOIN customer c_web ON ws.ws_bill_customer_sk = c_web.c_customer_sk
        JOIN household_demographics hd_web ON ws.ws_bill_hdemo_sk = hd_web.hd_demo_sk
        LEFT JOIN web_returns wr ON wr.wr_order_number = ws.ws_order_number AND wr.wr_item_sk = i.i_item_sk
        LEFT JOIN date_dim d_wr ON wr.wr_returned_date_sk = d_wr.d_date_sk
        LEFT JOIN customer c_wr_refund ON wr.wr_refunded_customer_sk = c_wr_refund.c_customer_sk
        LEFT JOIN household_demographics hd_wr ON wr.wr_refunded_hdemo_sk = hd_wr.hd_demo_sk
    WHERE
        d_cs.d_year = 2001
        AND i.i_brand = 'Brand#23'
        AND c_bill.c_preferred_cust_flag = 'Y'
    GROUP BY
        d_cs.d_year,
        i.i_category
)
SELECT
    d_year,
    i_category,
    catalog_sales_net,
    store_sales_net,
    web_sales_net,
    catalog_returns_loss,
    store_returns_loss,
    web_returns_loss,
    net_revenue,
    ROW_NUMBER() OVER (PARTITION BY d_year ORDER BY net_revenue DESC) AS revenue_rank
FROM agg
ORDER BY net_revenue DESC
LIMIT 100

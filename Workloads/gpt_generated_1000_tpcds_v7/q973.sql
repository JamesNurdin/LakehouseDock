WITH joined AS (
    SELECT
        c.c_customer_sk,
        hd.hd_demo_sk,
        s.s_store_sk,
        wp.wp_web_page_sk,
        SUM(ss.ss_net_profit) AS store_profit,
        SUM(cs.cs_net_profit) AS catalog_profit,
        SUM(ws.ws_net_profit) AS web_profit,
        SUM(cr.cr_net_loss) AS catalog_return_loss,
        SUM(wr.wr_net_loss) AS web_return_loss
    FROM
        store_sales ss
        JOIN store s
            ON ss.ss_store_sk = s.s_store_sk
        JOIN time_dim td
            ON ss.ss_sold_time_sk = td.t_time_sk
        JOIN customer c
            ON ss.ss_customer_sk = c.c_customer_sk
        JOIN household_demographics hd
            ON ss.ss_hdemo_sk = hd.hd_demo_sk
        /* Join catalog sales that share the same time, customer and household demo */
        JOIN catalog_sales cs
            ON cs.cs_sold_time_sk = td.t_time_sk
            AND cs.cs_bill_customer_sk = c.c_customer_sk
            AND cs.cs_bill_hdemo_sk = hd.hd_demo_sk
        /* Catalog returns linked to the catalog sale */
        JOIN catalog_returns cr
            ON cr.cr_order_number = cs.cs_order_number
            AND cr.cr_item_sk = cs.cs_item_sk
            AND cr.cr_refunded_customer_sk = c.c_customer_sk
            AND cr.cr_refunded_hdemo_sk = hd.hd_demo_sk
        /* Join web sales that share the same time, customer and household demo */
        JOIN web_sales ws
            ON ws.ws_sold_time_sk = td.t_time_sk
            AND ws.ws_bill_customer_sk = c.c_customer_sk
            AND ws.ws_bill_hdemo_sk = hd.hd_demo_sk
        /* Web page linked to the web sale */
        JOIN web_page wp
            ON ws.ws_web_page_sk = wp.wp_web_page_sk
        /* Web returns linked to the web sale */
        JOIN web_returns wr
            ON wr.wr_order_number = ws.ws_order_number
            AND wr.wr_item_sk = ws.ws_item_sk
            AND wr.wr_refunded_customer_sk = c.c_customer_sk
            AND wr.wr_refunded_hdemo_sk = hd.hd_demo_sk
            AND wr.wr_web_page_sk = wp.wp_web_page_sk
    WHERE
        s.s_state = 'CA'
        AND wp.wp_type = 'content'
        AND hd.hd_income_band_sk BETWEEN 3 AND 5
        AND ss.ss_quantity > 2
        AND cs.cs_quantity < 10
        AND ws.ws_quantity <= 5
        AND cr.cr_return_amount > 0
        AND wr.wr_return_amt > 0
    GROUP BY
        c.c_customer_sk,
        hd.hd_demo_sk,
        s.s_store_sk,
        wp.wp_web_page_sk
)
SELECT
    hd_demo_sk,
    AVG(total_profit) AS avg_total_profit,
    SUM(total_return_loss) AS total_return_loss
FROM (
    SELECT
        c_customer_sk,
        hd_demo_sk,
        s_store_sk,
        wp_web_page_sk,
        (store_profit + catalog_profit + web_profit) AS total_profit,
        (catalog_return_loss + web_return_loss) AS total_return_loss
    FROM joined
) agg
GROUP BY hd_demo_sk
HAVING SUM(total_return_loss) > 1000
ORDER BY avg_total_profit DESC
LIMIT 10

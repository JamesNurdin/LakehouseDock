WITH catalog_agg AS (
    SELECT
        cr.cr_refunded_customer_sk AS customer_sk,
        SUM(cr.cr_net_loss) AS catalog_net_loss,
        SUM(cs.cs_net_profit) AS catalog_sales_profit,
        COUNT(*) AS catalog_return_cnt
    FROM catalog_returns cr
    JOIN catalog_sales cs
        ON cr.cr_order_number = cs.cs_order_number
        AND cr.cr_item_sk = cs.cs_item_sk
    JOIN customer c
        ON cr.cr_refunded_customer_sk = c.c_customer_sk
    JOIN customer_address ca
        ON cr.cr_refunded_addr_sk = ca.ca_address_sk
    GROUP BY cr.cr_refunded_customer_sk
),
store_agg AS (
    SELECT
        sr.sr_customer_sk AS customer_sk,
        SUM(sr.sr_net_loss) AS store_net_loss,
        COUNT(*) AS store_return_cnt
    FROM store_returns sr
    JOIN customer c
        ON sr.sr_customer_sk = c.c_customer_sk
    JOIN customer_address ca
        ON sr.sr_addr_sk = ca.ca_address_sk
    GROUP BY sr.sr_customer_sk
),
web_agg AS (
    SELECT
        wr.wr_refunded_customer_sk AS customer_sk,
        SUM(wr.wr_net_loss) AS web_net_loss,
        COUNT(*) AS web_return_cnt
    FROM web_returns wr
    JOIN customer c
        ON wr.wr_refunded_customer_sk = c.c_customer_sk
    JOIN customer_address ca
        ON wr.wr_refunded_addr_sk = ca.ca_address_sk
    GROUP BY wr.wr_refunded_customer_sk
)
SELECT
    c.c_customer_id,
    c.c_first_name,
    c.c_last_name,
    ca.ca_state,
    COALESCE(ca_agg.catalog_net_loss, 0) + COALESCE(st_agg.store_net_loss, 0) + COALESCE(wb_agg.web_net_loss, 0) AS total_net_loss,
    COALESCE(ca_agg.catalog_return_cnt, 0) + COALESCE(st_agg.store_return_cnt, 0) + COALESCE(wb_agg.web_return_cnt, 0) AS total_return_cnt,
    COALESCE(ca_agg.catalog_sales_profit, 0) AS total_sales_profit_of_returned_items,
    RANK() OVER (
        ORDER BY COALESCE(ca_agg.catalog_net_loss, 0) + COALESCE(st_agg.store_net_loss, 0) + COALESCE(wb_agg.web_net_loss, 0) DESC
    ) AS loss_rank
FROM customer c
JOIN customer_address ca
    ON c.c_current_addr_sk = ca.ca_address_sk
LEFT JOIN catalog_agg ca_agg
    ON c.c_customer_sk = ca_agg.customer_sk
LEFT JOIN store_agg st_agg
    ON c.c_customer_sk = st_agg.customer_sk
LEFT JOIN web_agg wb_agg
    ON c.c_customer_sk = wb_agg.customer_sk
ORDER BY total_net_loss DESC
LIMIT 100

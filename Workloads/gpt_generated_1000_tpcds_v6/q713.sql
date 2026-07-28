WITH ss_agg AS (
    SELECT
        ss_customer_sk,
        SUM(ss_ext_sales_price) AS total_sales,
        SUM(ss_quantity) AS total_quantity
    FROM store_sales
    WHERE ss_ext_list_price > 1000
    GROUP BY ss_customer_sk
),
cr_agg AS (
    SELECT
        cr_refunded_customer_sk AS customer_sk,
        SUM(cr_net_loss) AS total_cr_net_loss,
        SUM(cr_fee) AS total_cr_fee
    FROM catalog_returns
    WHERE cr_fee > 10
    GROUP BY cr_refunded_customer_sk
),
wr_agg AS (
    SELECT
        wr_refunded_customer_sk AS customer_sk,
        SUM(wr_net_loss) AS total_wr_net_loss,
        SUM(wr_return_quantity) AS total_wr_qty
    FROM web_returns
    WHERE wr_return_quantity > 1
    GROUP BY wr_refunded_customer_sk
)
SELECT
    c.c_customer_id,
    ss.total_sales,
    ss.total_quantity,
    cr.total_cr_net_loss,
    cr.total_cr_fee,
    wr.total_wr_net_loss,
    wr.total_wr_qty,
    (COALESCE(cr.total_cr_net_loss, 0) + COALESCE(wr.total_wr_net_loss, 0)) AS combined_net_loss,
    CASE
        WHEN (COALESCE(cr.total_cr_net_loss, 0) + COALESCE(wr.total_wr_net_loss, 0)) > 1000 THEN 'High'
        WHEN (COALESCE(cr.total_cr_net_loss, 0) + COALESCE(wr.total_wr_net_loss, 0)) > 0 THEN 'Medium'
        ELSE 'Low'
    END AS loss_category,
    RANK() OVER (ORDER BY (COALESCE(cr.total_cr_net_loss, 0) + COALESCE(wr.total_wr_net_loss, 0)) DESC) AS loss_rank
FROM customer c
LEFT JOIN ss_agg ss
    ON ss.ss_customer_sk = c.c_customer_sk
LEFT JOIN cr_agg cr
    ON cr.customer_sk = c.c_customer_sk
LEFT JOIN wr_agg wr
    ON wr.customer_sk = c.c_customer_sk
WHERE c.c_preferred_cust_flag = 'Y'
ORDER BY loss_rank
LIMIT 100

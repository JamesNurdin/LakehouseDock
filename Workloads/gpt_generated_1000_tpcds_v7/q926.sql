WITH per_customer AS (
    SELECT
        c.c_customer_sk,
        SUM(cr.cr_return_amount) AS cat_return_amount,
        SUM(cr.cr_net_loss) AS cat_net_loss,
        SUM(wr.wr_return_amt) AS web_return_amount,
        SUM(wr.wr_net_loss) AS web_net_loss
    FROM
        catalog_returns cr
        JOIN customer c ON cr.cr_refunded_customer_sk = c.c_customer_sk
        JOIN web_returns wr ON wr.wr_refunded_customer_sk = c.c_customer_sk
    WHERE
        cr.cr_return_amount > 100
        AND cr.cr_return_ship_cost BETWEEN 20 AND 200
        AND c.c_first_sales_date_sk = 2451628
        AND wr.wr_fee > 30
    GROUP BY
        c.c_customer_sk
)
SELECT
    AVG(t.total_return_amount) AS avg_total_return_amount,
    AVG(t.total_net_loss) AS avg_total_net_loss
FROM (
    SELECT
        c_customer_sk,
        (cat_return_amount + web_return_amount) AS total_return_amount,
        (cat_net_loss + web_net_loss) AS total_net_loss
    FROM per_customer
    WHERE (cat_net_loss + web_net_loss) > 500
) t

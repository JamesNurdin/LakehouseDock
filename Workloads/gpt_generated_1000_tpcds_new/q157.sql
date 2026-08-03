WITH full_data AS (
    SELECT
        cr.cr_returned_date_sk AS date_sk,
        cr.cr_return_amount AS amount,
        c.c_customer_sk,
        c.c_current_hdemo_sk
    FROM catalog_returns cr
    FULL OUTER JOIN customer c
        ON cr.cr_refunded_customer_sk = c.c_customer_sk
    WHERE cr.cr_ship_mode_sk = 20
       OR c.c_current_hdemo_sk = 89
),
union_data AS (
    SELECT
        c.c_customer_sk,
        cr.cr_returned_date_sk AS return_date_sk,
        cr.cr_return_amount AS amount,
        cr.cr_net_loss AS net_loss
    FROM catalog_returns cr
    JOIN customer c
        ON cr.cr_refunded_customer_sk = c.c_customer_sk
    WHERE c.c_current_hdemo_sk = 6580
      AND cr.cr_ship_mode_sk = 18
      AND cr.cr_return_quantity > 1
      AND cr.cr_return_amount > 10

    UNION DISTINCT

    SELECT
        c.c_customer_sk,
        wr.wr_returned_date_sk AS return_date_sk,
        wr.wr_return_amt AS amount,
        wr.wr_net_loss AS net_loss
    FROM web_returns wr
    JOIN customer c
        ON wr.wr_refunded_customer_sk = c.c_customer_sk
    WHERE c.c_current_cdemo_sk = 1114415
      AND wr.wr_fee > 5
      AND wr.wr_return_quantity > 2
      AND wr.wr_return_amt > 15
),
-- Lateral subquery to fetch total refunded amount per customer from catalog_returns
lateral_agg AS (
    SELECT
        ud.c_customer_sk,
        ud.return_date_sk,
        ud.amount,
        ud.net_loss,
        ca.total_customer_amount
    FROM union_data ud
    LEFT JOIN LATERAL (
        SELECT SUM(cr_return_amount) AS total_customer_amount
        FROM catalog_returns cr
        WHERE cr.cr_refunded_customer_sk = ud.c_customer_sk
    ) ca ON true
)
SELECT
    la.c_customer_sk,
    COUNT(*) AS return_events,
    SUM(la.amount) AS total_amount,
    AVG(la.net_loss) AS avg_net_loss,
    MAX(la.total_customer_amount) AS max_total_customer_amount,
    MAX(fd.amount) AS max_full_join_amount
FROM lateral_agg la
LEFT JOIN full_data fd
    ON fd.c_customer_sk = la.c_customer_sk
GROUP BY la.c_customer_sk
ORDER BY total_amount DESC
LIMIT 100

WITH base_agg AS (
    SELECT
        c.c_customer_id,
        p.p_promo_id,
        SUM(ss.ss_net_paid) AS store_net_paid,
        SUM(ws.ws_net_paid) AS web_net_paid,
        SUM(COALESCE(cr.cr_net_loss, 0)) AS catalog_return_loss,
        SUM(COALESCE(wr.wr_net_loss, 0)) AS web_return_loss
    FROM tpcds.store_sales ss
    JOIN tpcds.customer c
        ON ss.ss_customer_sk = c.c_customer_sk
    JOIN tpcds.customer_demographics cd
        ON ss.ss_cdemo_sk = cd.cd_demo_sk
    JOIN tpcds.household_demographics hd
        ON ss.ss_hdemo_sk = hd.hd_demo_sk
    JOIN tpcds.promotion p
        ON ss.ss_promo_sk = p.p_promo_sk
    JOIN tpcds.web_sales ws
        ON p.p_promo_sk = ws.ws_promo_sk
    JOIN tpcds.web_returns wr
        ON ws.ws_order_number = wr.wr_order_number
    JOIN tpcds.catalog_returns cr
        ON c.c_customer_sk = cr.cr_returning_customer_sk
    WHERE ss.ss_sold_date_sk BETWEEN 2449000 AND 2452000
      AND cd.cd_credit_rating = 'Good'
      AND c.c_birth_month = 5
      AND ss.ss_quantity > 2
    GROUP BY c.c_customer_id, p.p_promo_id
)
SELECT
    AVG(total_net_paid) AS avg_total_net_paid,
    AVG(total_loss) AS avg_total_loss
FROM (
    SELECT
        store_net_paid + web_net_paid AS total_net_paid,
        catalog_return_loss + web_return_loss AS total_loss
    FROM base_agg
) t
WHERE total_net_paid > 0

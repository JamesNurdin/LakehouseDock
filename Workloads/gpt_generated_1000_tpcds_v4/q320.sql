WITH cust_returns AS (
    SELECT
        cr.cr_refunded_customer_sk AS customer_sk,
        SUM(cr.cr_net_loss) AS catalog_net_loss,
        SUM(cr.cr_return_quantity) AS catalog_return_qty
    FROM catalog_returns cr
    GROUP BY cr.cr_refunded_customer_sk
),
store_agg AS (
    SELECT
        sr.sr_customer_sk AS customer_sk,
        SUM(sr.sr_net_loss) AS store_net_loss,
        SUM(sr.sr_return_quantity) AS store_return_qty
    FROM store_returns sr
    GROUP BY sr.sr_customer_sk
)
SELECT
    c.c_customer_id,
    cd.cd_gender,
    hd.hd_income_band_sk,
    cr_agg.catalog_net_loss,
    st_agg.store_net_loss,
    (cr_agg.catalog_net_loss + st_agg.store_net_loss) AS total_net_loss,
    ROW_NUMBER() OVER (ORDER BY (cr_agg.catalog_net_loss + st_agg.store_net_loss) DESC) AS loss_rank
FROM cust_returns cr_agg
INNER JOIN store_agg st_agg
    ON cr_agg.customer_sk = st_agg.customer_sk
INNER JOIN customer c
    ON c.c_customer_sk = cr_agg.customer_sk
INNER JOIN customer_demographics cd
    ON cd.cd_demo_sk = c.c_current_cdemo_sk
INNER JOIN household_demographics hd
    ON hd.hd_demo_sk = c.c_current_hdemo_sk
WHERE cr_agg.catalog_net_loss > 5000
  AND st_agg.store_net_loss > 2000
  AND hd.hd_income_band_sk IN (2, 9, 12)
  AND c.c_birth_year BETWEEN 1950 AND 1970
  AND cd.cd_gender = 'M'
ORDER BY total_net_loss DESC
LIMIT 100

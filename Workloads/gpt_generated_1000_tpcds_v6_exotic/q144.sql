WITH catalog_agg AS (
    SELECT
        w.w_warehouse_id,
        w.w_city,
        w.w_warehouse_sk,
        hd.hd_demo_sk,
        ib.ib_lower_bound,
        ib.ib_upper_bound,
        COUNT(DISTINCT cr.cr_order_number) AS orders_returned,
        SUM(cr.cr_net_loss) AS total_net_loss,
        AVG(cr.cr_return_amount) AS avg_return_amount
    FROM catalog_returns cr
    INNER JOIN household_demographics hd
        ON cr.cr_refunded_hdemo_sk = hd.hd_demo_sk
    INNER JOIN income_band ib
        ON hd.hd_income_band_sk = ib.ib_income_band_sk
    INNER JOIN warehouse w
        ON cr.cr_warehouse_sk = w.w_warehouse_sk
    WHERE ib.ib_upper_bound >= 100000
      AND w.w_country = 'United States'
      AND hd.hd_dep_count >= 5
    GROUP BY w.w_warehouse_id, w.w_city, w.w_warehouse_sk, hd.hd_demo_sk,
             ib.ib_lower_bound, ib.ib_upper_bound
),

store_agg AS (
    SELECT
        hd.hd_demo_sk,
        SUM(sr.sr_return_amt) AS store_return_total
    FROM store_returns sr
    INNER JOIN household_demographics hd
        ON sr.sr_hdemo_sk = hd.hd_demo_sk
    GROUP BY hd.hd_demo_sk
),

combined AS (
    SELECT
        ca.w_warehouse_id,
        ca.w_city,
        ca.ib_lower_bound,
        ca.ib_upper_bound,
        ca.orders_returned,
        ca.total_net_loss,
        ca.avg_return_amount,
        COALESCE(sa.store_return_total, 0) AS store_return_total,
        CASE
            WHEN ca.total_net_loss > (SELECT AVG(total_net_loss) FROM catalog_agg) THEN 'HIGH'
            ELSE 'NORMAL'
        END AS loss_category,
        ca.w_warehouse_sk
    FROM catalog_agg ca
    LEFT JOIN store_agg sa
        ON ca.hd_demo_sk = sa.hd_demo_sk
)

SELECT
    w_warehouse_id,
    w_city,
    ib_lower_bound,
    ib_upper_bound,
    orders_returned,
    total_net_loss,
    avg_return_amount,
    store_return_total,
    loss_category,
    RANK() OVER (ORDER BY total_net_loss DESC) AS net_loss_rank
FROM combined
ORDER BY total_net_loss DESC
LIMIT 100

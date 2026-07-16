WITH returns_agg AS (
    SELECT
        s.s_store_sk,
        s.s_store_name,
        s.s_city,
        d.d_year,
        d.d_month_seq,
        SUM(cr.cr_net_loss)                                 AS total_net_loss,
        SUM(cr.cr_return_amount)                            AS total_return_amount,
        SUM(cr.cr_return_quantity)                          AS total_return_quantity,
        COUNT(*)                                            AS total_returns,
        AVG(cd_ret.cd_purchase_estimate)                    AS avg_returning_purchase_estimate,
        AVG(cd_ref.cd_purchase_estimate)                    AS avg_refunded_purchase_estimate,
        SUM(CASE WHEN cd_ret.cd_gender = 'M' THEN 1 ELSE 0 END) AS male_returning_customers,
        SUM(CASE WHEN cd_ret.cd_gender = 'F' THEN 1 ELSE 0 END) AS female_returning_customers,
        SUM(CASE WHEN hd_ret.hd_buy_potential = 'HIGH' THEN 1 ELSE 0 END) AS high_buy_potential_returning,
        SUM(CASE WHEN hd_ref.hd_buy_potential = 'LOW'  THEN 1 ELSE 0 END) AS low_buy_potential_refunded
    FROM catalog_returns cr
    JOIN date_dim d
        ON cr.cr_returned_date_sk = d.d_date_sk
    JOIN store s
        ON s.s_closed_date_sk = d.d_date_sk
    JOIN customer_demographics cd_ret
        ON cr.cr_returning_cdemo_sk = cd_ret.cd_demo_sk
    JOIN household_demographics hd_ret
        ON cr.cr_returning_hdemo_sk = hd_ret.hd_demo_sk
    JOIN customer_demographics cd_ref
        ON cr.cr_refunded_cdemo_sk = cd_ref.cd_demo_sk
    JOIN household_demographics hd_ref
        ON cr.cr_refunded_hdemo_sk = hd_ref.hd_demo_sk
    GROUP BY
        s.s_store_sk,
        s.s_store_name,
        s.s_city,
        d.d_year,
        d.d_month_seq
)
SELECT
    s_store_sk,
    s_store_name,
    s_city,
    d_year,
    d_month_seq,
    total_net_loss,
    total_return_amount,
    total_return_quantity,
    total_returns,
    avg_returning_purchase_estimate,
    avg_refunded_purchase_estimate,
    male_returning_customers,
    female_returning_customers,
    high_buy_potential_returning,
    low_buy_potential_refunded,
    ROUND(100.0 * total_net_loss / SUM(total_net_loss) OVER (PARTITION BY s_store_sk), 2) AS net_loss_pct_of_store
FROM returns_agg
ORDER BY total_net_loss DESC
LIMIT 100

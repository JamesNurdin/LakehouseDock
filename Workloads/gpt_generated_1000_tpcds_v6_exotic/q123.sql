WITH
    base_joins AS (
        SELECT
            sr.sr_customer_sk,
            c.c_customer_id,
            c.c_first_name,
            c.c_last_name,
            cd.cd_gender,
            cd.cd_marital_status,
            hd.hd_income_band_sk,
            ib.ib_upper_bound,
            sr.sr_return_amt,
            sr.sr_return_ship_cost,
            sr.sr_refunded_cash,
            sr.sr_net_loss
        FROM store_returns sr
        JOIN customer c ON sr.sr_customer_sk = c.c_customer_sk
        JOIN customer_demographics cd ON sr.sr_cdemo_sk = cd.cd_demo_sk
        JOIN household_demographics hd ON sr.sr_hdemo_sk = hd.hd_demo_sk
        JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
        WHERE sr.sr_return_amt > 100
          AND sr.sr_return_ship_cost > 5
          AND cd.cd_gender = 'M'
          AND cd.cd_marital_status = 'M'
          AND hd.hd_dep_count <= 5
          AND ib.ib_upper_bound >= 50000
    ),
    agg_per_customer AS (
        SELECT
            sr_customer_sk,
            c_customer_id,
            c_first_name,
            c_last_name,
            hd_income_band_sk,
            ib_upper_bound,
            SUM(sr_net_loss) AS total_net_loss,
            COUNT(*) AS return_cnt
        FROM base_joins
        GROUP BY
            sr_customer_sk,
            c_customer_id,
            c_first_name,
            c_last_name,
            hd_income_band_sk,
            ib_upper_bound
    ),
    high_loss AS (
        SELECT
            *,
            RANK() OVER (PARTITION BY hd_income_band_sk ORDER BY total_net_loss DESC) AS loss_rank
        FROM agg_per_customer
        WHERE total_net_loss > (SELECT AVG(total_net_loss) FROM agg_per_customer)
    ),
    low_loss AS (
        SELECT
            *,
            RANK() OVER (PARTITION BY hd_income_band_sk ORDER BY total_net_loss ASC) AS loss_rank
        FROM agg_per_customer
        WHERE total_net_loss <= (SELECT AVG(total_net_loss) FROM agg_per_customer)
    )
SELECT
    c_customer_id,
    c_first_name,
    c_last_name,
    hd_income_band_sk,
    ib_upper_bound,
    total_net_loss,
    loss_rank,
    'HIGH' AS loss_category
FROM high_loss
UNION ALL
SELECT
    c_customer_id,
    c_first_name,
    c_last_name,
    hd_income_band_sk,
    ib_upper_bound,
    total_net_loss,
    loss_rank,
    'LOW' AS loss_category
FROM low_loss
ORDER BY total_net_loss DESC
LIMIT 100

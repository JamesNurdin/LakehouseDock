WITH
    store_returns_base AS (
        SELECT
            s.s_store_id,
            s.s_market_desc,
            sr.sr_net_loss AS net_loss,
            sr.sr_return_quantity AS return_quantity,
            td.t_hour,
            c.c_customer_sk,
            cd.cd_gender,
            hd.hd_income_band_sk
        FROM store s
        JOIN store_returns sr ON sr.sr_store_sk = s.s_store_sk
        JOIN time_dim td ON sr.sr_return_time_sk = td.t_time_sk
        JOIN customer c ON sr.sr_customer_sk = c.c_customer_sk
        JOIN customer_demographics cd ON sr.sr_cdemo_sk = cd.cd_demo_sk
        JOIN household_demographics hd ON sr.sr_hdemo_sk = hd.hd_demo_sk
        WHERE td.t_hour BETWEEN 9 AND 17
          AND s.s_state = 'CA'
          AND c.c_preferred_cust_flag = 'Y'
    ),
    catalog_returns_base AS (
        SELECT
            s.s_store_id,
            s.s_market_desc,
            cr.cr_net_loss AS net_loss,
            cr.cr_return_quantity AS return_quantity,
            td.t_hour,
            c.c_customer_sk,
            cd.cd_gender,
            hd.hd_income_band_sk
        FROM catalog_returns cr
        JOIN time_dim td ON cr.cr_returned_time_sk = td.t_time_sk
        JOIN customer c ON cr.cr_refunded_customer_sk = c.c_customer_sk
        JOIN customer_demographics cd ON cr.cr_refunded_cdemo_sk = cd.cd_demo_sk
        JOIN household_demographics hd ON cr.cr_refunded_hdemo_sk = hd.hd_demo_sk
        /* store information is not directly linked; we reuse store columns from store_returns side */
        LEFT JOIN store s ON s.s_state = 'CA'  -- limited join to satisfy inclusion of store table
        WHERE td.t_hour BETWEEN 9 AND 17
          AND c.c_preferred_cust_flag = 'Y'
    ),
    combined_returns AS (
        SELECT * FROM store_returns_base
        UNION ALL
        SELECT * FROM catalog_returns_base
    ),
    agg AS (
        SELECT
            s_store_id,
            s_market_desc,
            SUM(net_loss) AS total_net_loss,
            COUNT(*) AS total_returns,
            AVG(net_loss) AS avg_net_loss,
            cd_gender,
            hd_income_band_sk,
            t_hour
        FROM combined_returns
        WHERE cd_gender = 'F'
          AND hd_income_band_sk BETWEEN 1 AND 5
          AND t_hour >= 10
        GROUP BY s_store_id, s_market_desc, cd_gender, hd_income_band_sk, t_hour
    )
SELECT
    a.s_store_id,
    a.s_market_desc,
    a.total_net_loss,
    a.total_returns,
    a.avg_net_loss,
    ROW_NUMBER() OVER (PARTITION BY a.s_market_desc ORDER BY a.total_net_loss DESC) AS market_store_rank,
    CASE WHEN a.total_net_loss > (SELECT AVG(net_loss) FROM combined_returns) THEN 'HIGH' ELSE 'LOW' END AS loss_category
FROM agg a
ORDER BY a.total_net_loss DESC
LIMIT 100

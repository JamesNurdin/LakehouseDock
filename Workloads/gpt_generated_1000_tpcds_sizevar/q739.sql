WITH
    ship_mode_filtered AS (
        SELECT sm_ship_mode_sk, sm_code, sm_contract
        FROM ship_mode
        TABLESAMPLE BERNOULLI (20)
        WHERE sm_code = 'AIR'
          AND sm_contract = 'yVfotg7Tio3MVhBg6Bkn'
    ),
    ship_mode_final AS (
        SELECT sm_ship_mode_sk, sm_code, sm_contract
        FROM ship_mode_filtered
        EXCEPT
        SELECT sm_ship_mode_sk, sm_code, sm_contract
        FROM ship_mode
        WHERE sm_contract = 'Ek'
    ),
    catalog_pre AS (
        SELECT cr_returned_time_sk,
               cr_order_number,
               cr_return_amount,
               cr_net_loss,
               cr_ship_mode_sk,
               cr_refunded_cash,
               cr_returning_hdemo_sk
        FROM catalog_returns
        WHERE cr_refunded_cash > 1000
          AND cr_returning_hdemo_sk = 4163
    ),
    store_pre AS (
        SELECT sr_return_time_sk,
               sr_return_amt,
               sr_return_quantity,
               sr_store_sk,
               sr_ticket_number,
               sr_return_amt AS sr_return_amt_original
        FROM store_returns
        WHERE sr_return_amt > 50
    ),
    catalog_joined AS (
        SELECT
            c.cr_returned_time_sk AS time_sk,
            t.t_hour,
            c.cr_order_number,
            c.cr_return_amount,
            c.cr_net_loss,
            sm.sm_code,
            sm.sm_contract
        FROM catalog_pre c
        JOIN time_dim t
            ON c.cr_returned_time_sk = t.t_time_sk
        JOIN ship_mode_final sm
            ON c.cr_ship_mode_sk = sm.sm_ship_mode_sk
        WHERE t.t_hour BETWEEN 9 AND 17
          AND EXISTS (
              SELECT 1
              FROM ship_mode_filtered f
              WHERE f.sm_ship_mode_sk = c.cr_ship_mode_sk
          )
    ),
    store_joined AS (
        SELECT
            s.sr_return_time_sk AS time_sk,
            t.t_hour,
            s.sr_return_amt,
            s.sr_return_quantity,
            st.s_state,
            st.s_rec_start_date
        FROM store_pre s
        JOIN time_dim t
            ON s.sr_return_time_sk = t.t_time_sk
        JOIN store st
            ON s.sr_store_sk = st.s_store_sk
        WHERE st.s_state = 'CA'
          AND st.s_rec_start_date >= DATE '1999-01-01'
          AND st.s_rec_start_date < DATE '2002-01-01'
    ),
    full_combined AS (
        SELECT
            COALESCE(c.time_sk, s.time_sk) AS time_sk,
            COALESCE(c.t_hour, s.t_hour) AS hour,
            c.cr_order_number,
            c.cr_return_amount,
            c.cr_net_loss,
            c.sm_code,
            s.sr_return_amt,
            s.sr_return_quantity,
            s.s_state,
            s.s_rec_start_date
        FROM catalog_joined c
        FULL OUTER JOIN store_joined s
            ON c.time_sk = s.time_sk
    )
SELECT
    hour,
    sm_code,
    s_state,
    COUNT(DISTINCT cr_order_number) AS orders_cnt,
    SUM(cr_return_amount) AS total_catalog_return,
    SUM(sr_return_amt) AS total_store_return,
    AVG(cr_net_loss) AS avg_catalog_net_loss,
    MAX(sr_return_amt) AS max_store_return_amt
FROM full_combined
WHERE hour IS NOT NULL
GROUP BY hour, sm_code, s_state
ORDER BY total_store_return DESC
LIMIT 100

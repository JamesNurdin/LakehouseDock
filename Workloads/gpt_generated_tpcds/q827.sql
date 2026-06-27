WITH refunded AS (
    SELECT
        cd.cd_demo_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        SUM(cr.cr_net_loss) AS refunded_net_loss,
        SUM(cr.cr_return_amount) AS refunded_return_amount,
        COUNT(DISTINCT cr.cr_refunded_customer_sk) AS refunded_customer_cnt,
        COUNT(*) AS refunded_return_cnt
    FROM catalog_returns cr
    JOIN customer_demographics cd
        ON cr.cr_refunded_cdemo_sk = cd.cd_demo_sk
    GROUP BY
        cd.cd_demo_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status
),
returning AS (
    SELECT
        cd.cd_demo_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        SUM(cr.cr_net_loss) AS returning_net_loss,
        SUM(cr.cr_return_amount) AS returning_return_amount,
        COUNT(DISTINCT cr.cr_returning_customer_sk) AS returning_customer_cnt,
        COUNT(*) AS returning_return_cnt
    FROM catalog_returns cr
    JOIN customer_demographics cd
        ON cr.cr_returning_cdemo_sk = cd.cd_demo_sk
    GROUP BY
        cd.cd_demo_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status
),
store AS (
    SELECT
        cd.cd_demo_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        SUM(sr.sr_net_loss) AS store_net_loss,
        SUM(sr.sr_return_amt) AS store_return_amount,
        COUNT(DISTINCT sr.sr_customer_sk) AS store_customer_cnt,
        COUNT(*) AS store_return_cnt
    FROM store_returns sr
    JOIN customer_demographics cd
        ON sr.sr_cdemo_sk = cd.cd_demo_sk
    GROUP BY
        cd.cd_demo_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status
)
SELECT
    COALESCE(rf.cd_demo_sk, rt.cd_demo_sk, st.cd_demo_sk) AS cd_demo_sk,
    COALESCE(rf.cd_gender, rt.cd_gender, st.cd_gender) AS cd_gender,
    COALESCE(rf.cd_marital_status, rt.cd_marital_status, st.cd_marital_status) AS cd_marital_status,
    COALESCE(rf.cd_education_status, rt.cd_education_status, st.cd_education_status) AS cd_education_status,
    rf.refunded_net_loss,
    rt.returning_net_loss,
    st.store_net_loss,
    rf.refunded_return_amount,
    rt.returning_return_amount,
    st.store_return_amount,
    rf.refunded_customer_cnt,
    rt.returning_customer_cnt,
    st.store_customer_cnt,
    rf.refunded_return_cnt,
    rt.returning_return_cnt,
    st.store_return_cnt,
    (COALESCE(rf.refunded_net_loss, 0) + COALESCE(rt.returning_net_loss, 0) + COALESCE(st.store_net_loss, 0)) AS total_net_loss,
    (COALESCE(rf.refunded_return_amount, 0) + COALESCE(rt.returning_return_amount, 0) + COALESCE(st.store_return_amount, 0)) AS total_return_amount,
    RANK() OVER (
        PARTITION BY COALESCE(rf.cd_gender, rt.cd_gender, st.cd_gender)
        ORDER BY (COALESCE(rf.refunded_net_loss, 0) + COALESCE(rt.returning_net_loss, 0) + COALESCE(st.store_net_loss, 0)) DESC
    ) AS gender_net_loss_rank
FROM refunded rf
FULL OUTER JOIN returning rt
    ON rf.cd_demo_sk = rt.cd_demo_sk
FULL OUTER JOIN store st
    ON COALESCE(rf.cd_demo_sk, rt.cd_demo_sk) = st.cd_demo_sk
ORDER BY total_net_loss DESC
LIMIT 50

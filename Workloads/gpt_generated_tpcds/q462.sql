WITH catalog_ret AS (
    SELECT
        'catalog' AS return_channel,
        cr_returning_customer_sk AS customer_sk,
        cr_returning_cdemo_sk AS cdemo_sk,
        cr_return_quantity AS return_quantity,
        cr_return_amount AS return_amount,
        cr_net_loss AS net_loss
    FROM catalog_returns
),
store_ret AS (
    SELECT
        'store' AS return_channel,
        sr_customer_sk AS customer_sk,
        sr_cdemo_sk AS cdemo_sk,
        sr_return_quantity AS return_quantity,
        sr_return_amt AS return_amount,
        sr_net_loss AS net_loss
    FROM store_returns
),
web_ret AS (
    SELECT
        'web' AS return_channel,
        wr_returning_customer_sk AS customer_sk,
        wr_returning_cdemo_sk AS cdemo_sk,
        wr_return_quantity AS return_quantity,
        wr_return_amt AS return_amount,
        wr_net_loss AS net_loss
    FROM web_returns
),
all_returns AS (
    SELECT
        return_channel,
        customer_sk,
        cdemo_sk,
        return_quantity,
        return_amount,
        net_loss
    FROM catalog_ret
    UNION ALL
    SELECT
        return_channel,
        customer_sk,
        cdemo_sk,
        return_quantity,
        return_amount,
        net_loss
    FROM store_ret
    UNION ALL
    SELECT
        return_channel,
        customer_sk,
        cdemo_sk,
        return_quantity,
        return_amount,
        net_loss
    FROM web_ret
),
joined AS (
    SELECT
        ar.return_channel,
        cd.cd_gender,
        cd.cd_marital_status,
        ar.return_quantity,
        ar.return_amount,
        ar.net_loss,
        c.c_customer_sk
    FROM all_returns ar
    JOIN customer c
        ON ar.customer_sk = c.c_customer_sk
    JOIN customer_demographics cd
        ON ar.cdemo_sk = cd.cd_demo_sk
)
SELECT
    return_channel,
    cd_gender,
    cd_marital_status,
    SUM(return_quantity) AS total_return_quantity,
    SUM(return_amount)   AS total_return_amount,
    SUM(net_loss)        AS total_net_loss,
    COUNT(DISTINCT c_customer_sk) AS distinct_customers
FROM joined
GROUP BY
    return_channel,
    cd_gender,
    cd_marital_status
ORDER BY
    total_net_loss DESC

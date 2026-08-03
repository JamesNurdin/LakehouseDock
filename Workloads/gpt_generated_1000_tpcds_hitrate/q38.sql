WITH
    ss AS (
        SELECT * FROM tpcds.store_sales
    ),
    wr AS (
        SELECT * FROM tpcds.web_returns
    )
SELECT
    c_ss.c_customer_id,
    ca_ss.ca_state,
    cd_ss.cd_marital_status,
    SUM(ss.ss_ext_sales_price) AS total_sales,
    SUM(wr.wr_return_amt) AS total_returns,
    SUM(CASE WHEN cd_ss.cd_gender = 'M' THEN ss.ss_net_profit ELSE 0 END) AS male_profit,
    COUNT(DISTINCT c_ss.c_customer_sk) AS distinct_customers
FROM
    ss
RIGHT OUTER JOIN tpcds.customer AS c_ss
    ON ss.ss_customer_sk = c_ss.c_customer_sk
LEFT JOIN tpcds.customer_demographics AS cd_ss
    ON ss.ss_cdemo_sk = cd_ss.cd_demo_sk
LEFT JOIN tpcds.customer_address AS ca_ss
    ON ss.ss_addr_sk = ca_ss.ca_address_sk
LEFT JOIN wr
    ON wr.wr_refunded_customer_sk = c_ss.c_customer_sk
LEFT JOIN tpcds.customer AS c_ref
    ON wr.wr_returning_customer_sk = c_ref.c_customer_sk
LEFT JOIN tpcds.customer_demographics AS cd_ref
    ON wr.wr_refunded_cdemo_sk = cd_ref.cd_demo_sk
LEFT JOIN tpcds.customer_address AS ca_ref
    ON wr.wr_refunded_addr_sk = ca_ref.ca_address_sk
LEFT JOIN tpcds.customer_demographics AS cd_ret
    ON wr.wr_returning_cdemo_sk = cd_ret.cd_demo_sk
LEFT JOIN tpcds.customer_address AS ca_ret
    ON wr.wr_returning_addr_sk = ca_ret.ca_address_sk
GROUP BY
    c_ss.c_customer_id,
    ca_ss.ca_state,
    cd_ss.cd_marital_status
LIMIT 100

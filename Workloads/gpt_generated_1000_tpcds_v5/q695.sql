WITH joined AS (
    SELECT
        c.c_customer_sk,
        c.c_customer_id,
        c.c_preferred_cust_flag,
        cd.cd_purchase_estimate,
        ca.ca_suite_number,
        ss.ss_net_profit,
        wr.wr_net_loss,
        wp.wp_type
    FROM tpcds.customer c
    JOIN tpcds.store_sales ss
        ON ss.ss_customer_sk = c.c_customer_sk
    JOIN tpcds.customer_demographics cd
        ON ss.ss_cdemo_sk = cd.cd_demo_sk
    JOIN tpcds.customer_address ca
        ON ss.ss_addr_sk = ca.ca_address_sk
    JOIN tpcds.web_returns wr
        ON wr.wr_refunded_customer_sk = c.c_customer_sk
    JOIN tpcds.web_page wp
        ON wr.wr_web_page_sk = wp.wp_web_page_sk
    WHERE c.c_preferred_cust_flag = 'Y'
      AND cd.cd_purchase_estimate > 5000
      AND ca.ca_suite_number LIKE 'Suite %'
      AND wp.wp_type = 'content'
      AND ss.ss_sold_date_sk BETWEEN 2450000 AND 2452000
      AND wr.wr_returned_date_sk BETWEEN 2450000 AND 2452000
),
agg AS (
    SELECT
        c_customer_sk,
        c_customer_id,
        SUM(ss_net_profit) AS total_sales_profit,
        SUM(wr_net_loss) AS total_return_loss,
        SUM(ss_net_profit) - SUM(wr_net_loss) AS net_contribution,
        COUNT(*) AS transaction_count
    FROM joined
    GROUP BY c_customer_sk, c_customer_id
)
SELECT
    c_customer_sk,
    c_customer_id,
    total_sales_profit,
    total_return_loss,
    net_contribution,
    RANK() OVER (ORDER BY net_contribution DESC) AS profit_rank,
    transaction_count
FROM agg
ORDER BY net_contribution DESC
LIMIT 100

WITH returns_agg AS (
    SELECT
        wr.wr_refunded_customer_sk AS customer_sk,
        cd.cd_gender AS gender,
        SUM(wr.wr_net_loss) AS total_return_loss,
        COUNT(*) AS return_cnt
    FROM web_returns wr
    JOIN customer c ON wr.wr_refunded_customer_sk = c.c_customer_sk
    JOIN customer_demographics cd ON wr.wr_refunded_cdemo_sk = cd.cd_demo_sk
    WHERE c.c_preferred_cust_flag = 'Y'
      AND cd.cd_gender = 'F'
    GROUP BY wr.wr_refunded_customer_sk, cd.cd_gender
)
SELECT
    s.s_store_id,
    s.s_store_name,
    cd.cd_gender,
    COUNT(DISTINCT ss.ss_customer_sk) AS num_customers,
    SUM(ss.ss_net_profit) AS total_net_profit,
    COALESCE(SUM(r.total_return_loss), 0) AS total_return_loss,
    (SUM(ss.ss_net_profit) - COALESCE(SUM(r.total_return_loss), 0)) AS net_profit_after_returns,
    RANK() OVER (ORDER BY (SUM(ss.ss_net_profit) - COALESCE(SUM(r.total_return_loss), 0)) DESC) AS profit_rank
FROM store_sales ss
JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
JOIN customer_demographics cd ON ss.ss_cdemo_sk = cd.cd_demo_sk
JOIN store s ON ss.ss_store_sk = s.s_store_sk
LEFT JOIN returns_agg r ON c.c_customer_sk = r.customer_sk AND cd.cd_gender = r.gender
WHERE c.c_preferred_cust_flag = 'Y'
  AND cd.cd_gender = 'F'
  AND s.s_state = 'CA'
  AND ss.ss_sold_date_sk BETWEEN 2450000 AND 2453000
GROUP BY s.s_store_id, s.s_store_name, cd.cd_gender
HAVING SUM(ss.ss_net_profit) > 10000
ORDER BY net_profit_after_returns DESC
LIMIT 10

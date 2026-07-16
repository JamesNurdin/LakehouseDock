WITH filtered_returns AS (
    SELECT
        wr.wr_returned_date_sk,
        wr.wr_reason_sk,
        wr.wr_return_amt_inc_tax,
        wr.wr_net_loss,
        wr.wr_return_quantity,
        wr.wr_refunded_customer_sk
    FROM web_returns wr
    WHERE wr.wr_returned_date_sk BETWEEN 2450000 AND 2459999
),
customer_info AS (
    SELECT
        c.c_customer_sk,
        c.c_preferred_cust_flag,
        c.c_birth_country
    FROM customer c
    WHERE c.c_birth_country IN ('IRELAND', 'CYPRUS')
),
joined AS (
    SELECT
        r.r_reason_desc,
        ci.c_preferred_cust_flag,
        ci.c_birth_country,
        fr.wr_return_amt_inc_tax,
        fr.wr_net_loss,
        fr.wr_return_quantity
    FROM filtered_returns fr
    JOIN customer_info ci ON fr.wr_refunded_customer_sk = ci.c_customer_sk
    JOIN reason r ON fr.wr_reason_sk = r.r_reason_sk
)
SELECT
    r_reason_desc,
    c_preferred_cust_flag,
    c_birth_country,
    COUNT(*) AS num_returns,
    SUM(wr_return_quantity) AS total_quantity,
    SUM(wr_return_amt_inc_tax) AS total_return_amount,
    SUM(wr_net_loss) AS total_net_loss,
    AVG(wr_net_loss) AS avg_net_loss,
    RANK() OVER (PARTITION BY c_preferred_cust_flag ORDER BY SUM(wr_net_loss) DESC) AS reason_rank_by_pref_flag
FROM joined
GROUP BY r_reason_desc, c_preferred_cust_flag, c_birth_country
HAVING SUM(wr_net_loss) > 0
ORDER BY total_net_loss DESC
LIMIT 20

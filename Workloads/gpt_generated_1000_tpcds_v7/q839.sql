WITH joined AS (
    SELECT
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        r.r_reason_desc,
        sr.sr_net_loss,
        wr.wr_net_loss
    FROM store_returns sr
    JOIN customer c ON sr.sr_customer_sk = c.c_customer_sk
    JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
    JOIN web_returns wr
        ON wr.wr_refunded_customer_sk = c.c_customer_sk
        AND wr.wr_reason_sk = r.r_reason_sk
    WHERE c.c_birth_country = 'United States'
      AND c.c_preferred_cust_flag = 'Y'
      AND r.r_reason_desc LIKE '%price%'
      AND sr.sr_return_amt > 50
      AND sr.sr_fee BETWEEN 10 AND 80
      AND wr.wr_return_tax < 100
      AND sr.sr_reversed_charge IS NOT NULL
)
SELECT
    c_customer_id,
    c_first_name,
    c_last_name,
    r_reason_desc,
    SUM(sr_net_loss) AS store_loss,
    SUM(wr_net_loss) AS web_loss,
    SUM(sr_net_loss) + SUM(wr_net_loss) AS total_loss,
    RANK() OVER (ORDER BY SUM(sr_net_loss) + SUM(wr_net_loss) DESC) AS loss_rank
FROM joined
GROUP BY c_customer_id, c_first_name, c_last_name, r_reason_desc
ORDER BY total_loss DESC
LIMIT 100

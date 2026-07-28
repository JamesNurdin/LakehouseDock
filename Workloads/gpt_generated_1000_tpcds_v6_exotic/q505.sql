WITH filtered_returns AS (
    SELECT
        wr.wr_refunded_customer_sk,
        wr.wr_refunded_cdemo_sk,
        wr.wr_refunded_addr_sk,
        wr.wr_return_quantity,
        wr.wr_net_loss,
        wr.wr_returned_date_sk
    FROM web_returns wr
    WHERE wr.wr_return_quantity > 1
      AND wr.wr_net_loss > 0
      AND wr.wr_returned_date_sk BETWEEN 2450000 AND 2455000
      AND EXISTS (
          SELECT 1
          FROM web_returns wr2
          WHERE wr2.wr_refunded_customer_sk = wr.wr_refunded_customer_sk
            AND wr2.wr_net_loss > 50
      )
)
SELECT
    c.c_customer_id,
    c.c_first_name,
    c.c_last_name,
    c.c_birth_month,
    ca.ca_state,
    cd.cd_gender,
    SUM(fr.wr_net_loss) AS total_net_loss,
    CASE
        WHEN SUM(fr.wr_net_loss) > 500 THEN 'High'
        WHEN SUM(fr.wr_net_loss) > 200 THEN 'Medium'
        ELSE 'Low'
    END AS loss_category,
    RANK() OVER (ORDER BY SUM(fr.wr_net_loss) DESC) AS loss_rank,
    COUNT(*) OVER (PARTITION BY cd.cd_gender) AS returns_per_gender
FROM filtered_returns fr
JOIN customer c
    ON fr.wr_refunded_customer_sk = c.c_customer_sk
JOIN customer_address ca
    ON fr.wr_refunded_addr_sk = ca.ca_address_sk
JOIN customer_demographics cd
    ON fr.wr_refunded_cdemo_sk = cd.cd_demo_sk
WHERE c.c_birth_month IN (1, 3, 7)
  AND c.c_birth_year BETWEEN 1950 AND 1965
  AND ca.ca_state = 'CA'
  AND cd.cd_credit_rating = 'A'
GROUP BY
    c.c_customer_id,
    c.c_first_name,
    c.c_last_name,
    c.c_birth_month,
    ca.ca_state,
    cd.cd_gender
ORDER BY total_net_loss DESC
LIMIT 100

WITH wr_agg AS (
    SELECT
        wr_refunded_customer_sk,
        SUM(wr_refunded_cash) AS total_refunded_cash,
        SUM(wr_net_loss) AS total_net_loss,
        COUNT(*) AS return_cnt
    FROM web_returns
    WHERE wr_refunded_cash > 100
      AND wr_return_ship_cost > 10
      AND wr_return_quantity > 1
    GROUP BY wr_refunded_customer_sk
)
SELECT DISTINCT
    c.c_customer_id,
    c.c_first_name,
    c.c_last_name,
    c.c_salutation,
    wa.total_refunded_cash,
    wa.total_net_loss,
    wa.return_cnt,
    CASE WHEN wa.total_net_loss > 1000 THEN 'HIGH' ELSE 'LOW' END AS loss_risk,
    RANK() OVER (PARTITION BY c.c_salutation ORDER BY wa.total_refunded_cash DESC) AS salutation_rank
FROM wr_agg wa
JOIN customer c
    ON wa.wr_refunded_customer_sk = c.c_customer_sk
WHERE c.c_salutation IN ('Dr.', 'Mrs.')
  AND c.c_last_review_date > 2452400
  AND c.c_birth_year BETWEEN 1950 AND 1990
ORDER BY salutation_rank, wa.total_refunded_cash DESC
LIMIT 100

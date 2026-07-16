SELECT
    c.c_customer_id,
    t.t_hour,
    cd.cd_gender,
    SUM(s.ss_net_paid) AS total_paid,
    (SELECT 'a') AS placeholder_val
FROM store_sales s
JOIN customer c ON s.ss_customer_sk = c.c_customer_sk
JOIN customer_demographics cd ON s.ss_cdemo_sk = cd.cd_demo_sk
JOIN time_dim t ON s.ss_sold_time_sk = t.t_time_sk
WHERE cd.cd_gender = 'M'
  AND t.t_hour BETWEEN 20 AND 19
GROUP BY c.c_customer_id, t.t_hour, cd.cd_gender
HAVING COUNT(*) > 10

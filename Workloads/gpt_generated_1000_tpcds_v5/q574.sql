WITH filtered_customers AS (
    SELECT c.c_customer_sk, c.c_first_name, c.c_last_name
    FROM customer c
    WHERE c.c_first_name LIKE 'A%'
)
SELECT
    hd.hd_demo_sk,
    hd.hd_buy_potential,
    regexp_extract(i.i_formulation, '(\\d+)', 1) AS formulation_number,
    SUM(cs.cs_net_profit) AS total_net_profit,
    COUNT(DISTINCT fc.c_customer_sk) AS distinct_customers,
    COUNT(DISTINCT wr.wr_order_number) AS distinct_returns
FROM catalog_sales cs
JOIN filtered_customers fc ON cs.cs_bill_customer_sk = fc.c_customer_sk
JOIN item i ON cs.cs_item_sk = i.i_item_sk
JOIN household_demographics hd ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
JOIN time_dim t ON cs.cs_sold_time_sk = t.t_time_sk
LEFT JOIN web_returns wr ON wr.wr_item_sk = i.i_item_sk
    AND wr.wr_returned_time_sk = t.t_time_sk
WHERE
    regexp_like(i.i_formulation, '^[a-z]+\\d+')
    AND i.i_units LIKE 'L%'
    AND t.t_hour BETWEEN 9 AND 17
GROUP BY
    hd.hd_demo_sk,
    hd.hd_buy_potential,
    regexp_extract(i.i_formulation, '(\\d+)', 1)
ORDER BY total_net_profit DESC
LIMIT 100

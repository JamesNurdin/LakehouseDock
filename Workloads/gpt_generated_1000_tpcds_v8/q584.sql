WITH sampled_returns AS (
    SELECT *
    FROM web_returns TABLESAMPLE BERNOULLI (10)
),
filtered_a AS (
    SELECT DISTINCT sr.wr_order_number
    FROM sampled_returns sr
    JOIN time_dim td ON sr.wr_returned_time_sk = td.t_time_sk
    JOIN reason r ON sr.wr_reason_sk = r.r_reason_sk
    WHERE td.t_meal_time = 'dinner'
      AND td.t_second BETWEEN 5 AND 20
      AND r.r_reason_id IN ('AAAAAAAAPAAAAAAA','AAAAAAAAGAAAAAAA')
      AND sr.wr_return_amt > 10
      AND sr.wr_fee < 50
),
filtered_b AS (
    SELECT DISTINCT sr.wr_order_number
    FROM sampled_returns sr
    JOIN web_page wp ON sr.wr_web_page_sk = wp.wp_web_page_sk
    WHERE wp.wp_type = 'content'
      AND wp.wp_char_count > 500
      AND sr.wr_return_quantity >= 1
      AND sr.wr_return_tax BETWEEN 0 AND 30
      AND sr.wr_return_ship_cost IS NOT NULL
),
common_orders AS (
    SELECT wr_order_number FROM filtered_a
    INTERSECT
    SELECT wr_order_number FROM filtered_b
)
SELECT
    sr.wr_order_number,
    td.t_time_id,
    r.r_reason_desc,
    wp.wp_url,
    sr.wr_return_amt,
    sr.wr_return_tax,
    sr.wr_return_quantity,
    ROW_NUMBER() OVER (PARTITION BY td.t_time_id ORDER BY sr.wr_return_amt DESC) AS rn,
    COUNT(DISTINCT wp.wp_url) OVER (PARTITION BY sr.wr_order_number) AS distinct_pages,
    COUNT(DISTINCT r.r_reason_desc) OVER (PARTITION BY sr.wr_order_number) AS distinct_reasons
FROM sampled_returns sr
JOIN time_dim td ON sr.wr_returned_time_sk = td.t_time_sk
JOIN reason r ON sr.wr_reason_sk = r.r_reason_sk
JOIN web_page wp ON sr.wr_web_page_sk = wp.wp_web_page_sk
JOIN common_orders co ON sr.wr_order_number = co.wr_order_number
WHERE td.t_time_id LIKE 'AAAAAAA%'
  AND sr.wr_net_loss > 0
ORDER BY sr.wr_return_amt DESC
OFFSET 10 LIMIT 100

WITH sales_promo AS (
    SELECT
        cs.cs_order_number,
        cs.cs_sold_date_sk,
        cs.cs_sold_time_sk,
        cs.cs_sales_price,
        cs.cs_quantity,
        cs.cs_net_paid,
        cs.cs_net_profit,
        cs.cs_promo_sk,
        p.p_promo_name,
        p.p_channel_dmail,
        p.p_discount_active,
        t.t_hour,
        t.t_sub_shift,
        t.t_second
    FROM catalog_sales cs
    JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
    JOIN time_dim t ON cs.cs_sold_time_sk = t.t_time_sk
    WHERE cs.cs_sales_price > 20.00
      AND cs.cs_quantity >= 2
      AND p.p_channel_dmail = 'Y'
      AND p.p_discount_active = 'Y'
      AND t.t_sub_shift = 'morning'
      AND t.t_second BETWEEN 1 AND 10
)
SELECT
    sp.cs_order_number,
    sp.cs_sold_date_sk,
    sp.p_promo_name,
    sp.t_hour,
    SUM(sp.cs_sales_price * sp.cs_quantity) AS total_sales_amount,
    AVG(sp.cs_net_profit) AS avg_profit,
    COUNT(DISTINCT sp.cs_promo_sk) AS promo_count,
    MIN(sp.cs_sales_price) AS min_price,
    MAX(sp.cs_sales_price) AS max_price
FROM sales_promo sp
JOIN web_returns wr
  ON wr.wr_returned_time_sk = sp.cs_sold_time_sk
  AND wr.wr_order_number = sp.cs_order_number
WHERE EXISTS (
        SELECT 1
        FROM web_returns wr2
        WHERE wr2.wr_order_number = sp.cs_order_number
          AND wr2.wr_return_amt > 0
    )
  AND NOT EXISTS (
        SELECT 1
        FROM promotion p2
        WHERE p2.p_promo_sk = sp.cs_promo_sk
          AND p2.p_channel_email = 'Y'
    )
GROUP BY
    sp.cs_order_number,
    sp.cs_sold_date_sk,
    sp.p_promo_name,
    sp.t_hour
HAVING SUM(sp.cs_sales_price * sp.cs_quantity) > 5000
ORDER BY total_sales_amount DESC
LIMIT 100

WITH sales_agg AS (
    SELECT
        d.d_year,
        p.p_promo_name,
        c.c_customer_id,
        SUM(ws.ws_net_profit) AS total_profit,
        COUNT(*) AS sales_cnt
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
    JOIN household_demographics hd ON ws.ws_bill_hdemo_sk = hd.hd_demo_sk
    WHERE d.d_year = 2001
      AND p.p_cost > 500
      AND ws.ws_quantity > 2
      AND c.c_birth_month = 7
    GROUP BY d.d_year, p.p_promo_name, c.c_customer_id
)
SELECT
    d_year,
    p_promo_name,
    c_customer_id,
    total_profit,
    sales_cnt,
    RANK() OVER (PARTITION BY d_year ORDER BY total_profit DESC) AS profit_rank,
    CASE WHEN total_profit > 1000 THEN 'High' ELSE 'Medium' END AS profit_category
FROM sales_agg
ORDER BY d_year, profit_rank
LIMIT 100

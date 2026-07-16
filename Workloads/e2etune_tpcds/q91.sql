WITH sales_agg AS (
    SELECT
        ca.ca_state,
        p.p_promo_id,
        SUM(ss.ss_net_profit) AS total_profit,
        SUM(ss.ss_ext_sales_price) AS total_sales,
        AVG(ss.ss_coupon_amt) AS avg_coupon,
        COUNT(*) AS sales_cnt,
        SUM(ss.ss_quantity) AS total_qty
    FROM store_sales ss
    JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
    JOIN customer_address ca ON ss.ss_addr_sk = ca.ca_address_sk
        AND c.c_current_addr_sk = ca.ca_address_sk
    JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
    WHERE ss.ss_sold_date_sk BETWEEN 2450000 AND 2453650
      AND p.p_channel_email IS NOT NULL
      AND p.p_cost > 0
    GROUP BY ca.ca_state, p.p_promo_id
)
SELECT *
FROM (
    SELECT
        ca_state,
        p_promo_id,
        total_profit,
        total_sales,
        avg_coupon,
        sales_cnt,
        total_qty,
        total_profit / SUM(total_profit) OVER (PARTITION BY ca_state) AS profit_pct_of_state,
        RANK() OVER (PARTITION BY ca_state ORDER BY total_profit DESC) AS profit_rank_state
    FROM sales_agg
) t
WHERE profit_rank_state <= 5
ORDER BY ca_state, profit_rank_state

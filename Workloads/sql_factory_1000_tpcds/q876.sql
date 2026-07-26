WITH sales_joined AS (
    SELECT
        ss.ss_sold_date_sk,
        ss.ss_store_sk,
        ca.ca_state,
        td.t_hour,
        ss.ss_net_profit,
        ss.ss_ext_sales_price,
        ss.ss_ext_discount_amt
    FROM store_sales ss
    JOIN customer_address ca
        ON ss.ss_addr_sk = ca.ca_address_sk
    JOIN promotion p
        ON ss.ss_promo_sk = p.p_promo_sk
    JOIN time_dim td
        ON ss.ss_sold_time_sk = td.t_time_sk
),
agg_sales AS (
    SELECT
        ss_sold_date_sk,
        ss_store_sk,
        ca_state,
        t_hour,
        SUM(ss_net_profit) AS total_net_profit,
        SUM(ss_ext_discount_amt) AS total_discount,
        SUM(ss_ext_sales_price) AS total_sales_price
    FROM sales_joined
    GROUP BY ss_sold_date_sk, ss_store_sk, ca_state, t_hour
)
SELECT
    ss_sold_date_sk,
    ss_store_sk,
    ca_state,
    t_hour,
    total_net_profit,
    total_discount,
    CASE WHEN total_sales_price > 0 THEN total_discount / total_sales_price ELSE 0 END AS discount_rate,
    RANK() OVER (PARTITION BY ss_sold_date_sk ORDER BY total_net_profit DESC) AS profit_rank
FROM agg_sales
ORDER BY ss_sold_date_sk, profit_rank

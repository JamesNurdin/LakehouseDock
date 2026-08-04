WITH diff_orders AS (
    SELECT cs_order_number
    FROM catalog_sales
    WHERE cs_quantity > 50
    EXCEPT
    SELECT cs_order_number
    FROM catalog_sales
    WHERE cs_list_price < 30
),

base AS (
    SELECT
        cs.cs_order_number,
        cs.cs_ship_mode_sk,
        cs.cs_promo_sk,
        cs.cs_bill_customer_sk,
        cs.cs_quantity,
        cs.cs_net_profit,
        cs.cs_ext_sales_price,
        p.p_channel_tv,
        p.p_end_date_sk,
        sm.sm_carrier,
        sm.sm_code,
        c.c_birth_country,
        c.c_birth_day,
        wr.wr_return_amt_inc_tax
    FROM catalog_sales cs
    JOIN diff_orders d ON cs.cs_order_number = d.cs_order_number
    JOIN customer c ON cs.cs_bill_customer_sk = c.c_customer_sk
    JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
    JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    LEFT JOIN web_returns wr ON wr.wr_refunded_customer_sk = c.c_customer_sk
    WHERE
        sm.sm_code = 'AIR'
        AND p.p_channel_tv = 'N'
        AND c.c_birth_country = 'SWITZERLAND'
        AND wr.wr_return_amt_inc_tax > 500
),

agg AS (
    SELECT
        sm_carrier,
        sm_code,
        COUNT(DISTINCT cs_order_number) AS order_count,
        SUM(cs_quantity) AS total_quantity,
        SUM(cs_net_profit) AS total_net_profit,
        AVG(cs_ext_sales_price) AS avg_sales_price,
        MIN(cs_net_profit) AS min_net_profit,
        MAX(cs_net_profit) AS max_net_profit
    FROM base
    GROUP BY sm_carrier, sm_code
)

SELECT
    sm_carrier,
    sm_code,
    order_count,
    total_quantity,
    total_net_profit,
    avg_sales_price,
    min_net_profit,
    max_net_profit,
    ROW_NUMBER() OVER (PARTITION BY sm_carrier ORDER BY total_net_profit DESC) AS carrier_rank
FROM agg
ORDER BY total_net_profit DESC
OFFSET 0 LIMIT 100

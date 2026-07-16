WITH store_agg AS (
    SELECT
        ss_store_sk,
        SUM(ss_net_paid) AS total_net_paid,
        SUM(ss_net_profit) AS total_net_profit,
        SUM(ss_quantity) AS total_quantity,
        AVG(ss_ext_discount_amt) AS avg_discount,
        AVG(ss_coupon_amt) AS avg_coupon,
        COUNT(*) AS transaction_count
    FROM store_sales
    WHERE ss_sold_date_sk BETWEEN 2450815 AND 2451088
      AND ss_quantity > 0
    GROUP BY ss_store_sk
),
store_ranked AS (
    SELECT
        s.s_store_sk,
        s.s_store_name,
        s.s_city,
        s.s_state,
        s.s_country,
        s.s_floor_space,
        s.s_gmt_offset,
        a.total_net_paid,
        a.total_net_profit,
        a.total_quantity,
        a.avg_discount,
        a.avg_coupon,
        a.transaction_count,
        (a.total_net_profit / NULLIF(s.s_floor_space, 0)) AS profit_per_sqft,
        ROW_NUMBER() OVER (PARTITION BY s.s_state ORDER BY a.total_net_profit DESC) AS profit_rank_in_state
    FROM store s
    JOIN store_agg a ON s.s_store_sk = a.ss_store_sk
    WHERE s.s_country = 'United States'
)
SELECT
    s_state,
    s_city,
    s_store_name,
    total_net_paid,
    total_net_profit,
    profit_per_sqft,
    total_quantity,
    avg_discount,
    avg_coupon,
    transaction_count
FROM store_ranked
WHERE profit_rank_in_state <= 10
ORDER BY s_state, profit_rank_in_state

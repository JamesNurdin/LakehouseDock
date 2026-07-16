WITH promo_sales AS (
    SELECT
        cs.cs_net_profit,
        cs.cs_ext_discount_amt,
        cs.cs_ext_list_price,
        cs.cs_quantity,
        cs.cs_promo_sk,
        td.t_hour,
        td.t_shift,
        td.t_am_pm
    FROM catalog_sales cs
    JOIN time_dim td ON cs.cs_sold_time_sk = td.t_time_sk
    WHERE cs.cs_promo_sk IN (843, 587, 974)
      AND cs.cs_ext_list_price > 1000
),
agg AS (
    SELECT
        t_hour,
        t_shift,
        t_am_pm,
        COUNT(*) AS sales_cnt,
        SUM(cs_quantity) AS total_quantity,
        SUM(cs_net_profit) AS total_net_profit,
        SUM(cs_ext_discount_amt) AS total_discount,
        AVG(cs_net_profit) AS avg_net_profit,
        ROUND(SUM(cs_net_profit) / NULLIF(SUM(cs_ext_list_price), 0), 4) AS profit_margin
    FROM promo_sales
    GROUP BY t_hour, t_shift, t_am_pm
    HAVING SUM(cs_net_profit) < 0
)
SELECT
    t_hour,
    t_shift,
    t_am_pm,
    sales_cnt,
    total_quantity,
    total_net_profit,
    total_discount,
    avg_net_profit,
    profit_margin,
    ROW_NUMBER() OVER (ORDER BY total_net_profit ASC) AS loss_rank
FROM agg
ORDER BY total_net_profit ASC
LIMIT 20

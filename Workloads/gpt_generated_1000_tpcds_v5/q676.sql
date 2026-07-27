WITH sales_returns AS (
    SELECT
        cs.cs_order_number,
        cs.cs_quantity,
        cs.cs_net_profit,
        p.p_promo_name,
        p.p_discount_active,
        t.t_time,
        t.t_hour,
        wr.wr_return_quantity,
        wr.wr_net_loss,
        r.r_reason_desc,
        CASE WHEN cs.cs_net_profit > 0 THEN 'Profitable' ELSE 'Loss' END AS profit_flag
    FROM catalog_sales cs
    JOIN promotion p
        ON cs.cs_promo_sk = p.p_promo_sk
    JOIN time_dim t
        ON cs.cs_sold_time_sk = t.t_time_sk
    JOIN web_returns wr
        ON wr.wr_returned_time_sk = t.t_time_sk
    JOIN reason r
        ON wr.wr_reason_sk = r.r_reason_sk
    WHERE cs.cs_call_center_sk IN (10, 22, 31)
      AND cs.cs_ship_hdemo_sk BETWEEN 2000 AND 7000
      AND p.p_start_date_sk >= 2450500
      AND p.p_channel_press = 'N'
      AND t.t_time BETWEEN 1 AND 12
      AND r.r_reason_desc LIKE '%damage%'
),
agg AS (
    SELECT
        cs_order_number,
        p_promo_name,
        SUM(cs_quantity) AS total_qty_sold,
        SUM(wr_return_quantity) AS total_qty_returned,
        SUM(cs_net_profit) AS total_net_profit,
        SUM(wr_net_loss) AS total_net_loss,
        SUM(CASE WHEN profit_flag = 'Profitable' THEN cs_net_profit ELSE 0 END) AS profit_sum
    FROM sales_returns
    GROUP BY cs_order_number, p_promo_name
    HAVING SUM(cs_quantity) > 5
)
SELECT
    cs_order_number,
    p_promo_name,
    total_qty_sold,
    total_qty_returned,
    total_net_profit,
    total_net_loss,
    profit_sum,
    RANK() OVER (PARTITION BY p_promo_name ORDER BY total_net_profit DESC) AS profit_rank
FROM agg
ORDER BY total_net_profit DESC
LIMIT 100

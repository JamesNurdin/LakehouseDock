WITH sales_detail AS (
    SELECT
        ss.ss_sold_date_sk,
        ss.ss_item_sk,
        ss.ss_promo_sk,
        ss.ss_quantity,
        ss.ss_net_profit,
        ss.ss_ext_sales_price,
        i.i_item_id,
        i.i_product_name,
        i.i_current_price,
        d.d_year,
        d.d_month_seq,
        p.p_cost,
        p.p_promo_name,
        p.p_channel_details
    FROM store_sales ss
    JOIN date_dim d
        ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN item i
        ON ss.ss_item_sk = i.i_item_sk
    JOIN promotion p
        ON ss.ss_promo_sk = p.p_promo_sk
    WHERE d.d_year = 2001
      AND i.i_current_price > 100
      AND p.p_cost <= 2000
      AND ss.ss_quantity >= 5
      AND d.d_month_seq BETWEEN 1200 AND 1240
)
SELECT
    sd.d_year,
    sd.d_month_seq,
    sd.i_item_id,
    sd.i_product_name,
    sd.i_current_price,
    sd.p_promo_name,
    sd.ss_quantity,
    sd.ss_net_profit,
    CASE WHEN sd.ss_net_profit > 500 THEN 'High' ELSE 'Normal' END AS profit_tier,
    ROW_NUMBER() OVER (PARTITION BY sd.d_year, sd.d_month_seq ORDER BY sd.ss_net_profit DESC) AS profit_rank,
    SUM(sd.ss_ext_sales_price) OVER (
        PARTITION BY sd.d_year, sd.d_month_seq
        ORDER BY sd.ss_net_profit DESC
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    ) AS cum_sales_price
FROM sales_detail sd
ORDER BY sd.d_year, sd.d_month_seq, profit_rank
LIMIT 100

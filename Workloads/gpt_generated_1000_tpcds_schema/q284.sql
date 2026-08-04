WITH base_data AS (
    SELECT
        promotion.p_promo_id,
        promotion.p_promo_name,
        promotion.p_discount_active,
        time_dim.t_time_id,
        time_dim.t_time,
        time_dim.t_hour,
        web_page.wp_web_page_id,
        reason.r_reason_desc,
        store_sales.ss_ext_sales_price,
        store_sales.ss_net_profit,
        web_returns.wr_return_amt,
        web_returns.wr_net_loss
    FROM promotion
    JOIN store_sales ON store_sales.ss_promo_sk = promotion.p_promo_sk
    JOIN time_dim ON store_sales.ss_sold_time_sk = time_dim.t_time_sk
    JOIN web_returns ON web_returns.wr_returned_time_sk = time_dim.t_time_sk
    JOIN web_page ON web_returns.wr_web_page_sk = web_page.wp_web_page_sk
    JOIN reason ON web_returns.wr_reason_sk = reason.r_reason_sk
    WHERE promotion.p_channel_email = 'Y'
      AND promotion.p_response_target = 1
      AND time_dim.t_time IN (10, 18, 9)
      AND web_page.wp_rec_end_date BETWEEN DATE '1999-01-01' AND DATE '2000-12-31'
      AND reason.r_reason_desc LIKE '%purchase%'
      AND store_sales.ss_ext_sales_price > 1000
),
agg_data AS (
    SELECT
        p_promo_id,
        r_reason_desc,
        t_time,
        SUM(ss_ext_sales_price) AS total_sales,
        SUM(ss_net_profit) AS total_profit,
        SUM(wr_return_amt) AS total_return_amount,
        SUM(wr_net_loss) AS total_loss
    FROM base_data
    GROUP BY ROLLUP (p_promo_id, r_reason_desc, t_time)
),
high_profit AS (
    SELECT p_promo_id FROM agg_data WHERE total_profit > 5000
),
low_profit AS (
    SELECT p_promo_id FROM agg_data WHERE total_profit <= 1000
),
promo_diff AS (
    SELECT p_promo_id FROM high_profit
    EXCEPT
    SELECT p_promo_id FROM low_profit
),
ranked AS (
    SELECT
        p_promo_id,
        r_reason_desc,
        t_time,
        total_sales,
        total_profit,
        total_return_amount,
        total_loss,
        RANK() OVER (PARTITION BY p_promo_id ORDER BY total_profit DESC) AS profit_rank
    FROM agg_data
)
SELECT
    r.p_promo_id,
    r.r_reason_desc,
    r.t_time,
    r.total_sales,
    r.total_profit,
    r.total_return_amount,
    r.total_loss,
    CASE
        WHEN r.p_promo_id IS NOT NULL AND r.r_reason_desc IS NOT NULL AND r.t_time IS NOT NULL
        THEN r.profit_rank
    END AS profit_rank
FROM ranked r
JOIN promo_diff d ON r.p_promo_id = d.p_promo_id
ORDER BY r.total_profit DESC, r.p_promo_id
OFFSET 0 ROWS FETCH NEXT 100 ROWS ONLY

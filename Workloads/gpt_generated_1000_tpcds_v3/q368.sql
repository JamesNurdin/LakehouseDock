WITH sales_agg AS (
    SELECT
        s.s_store_id,
        s.s_state,
        p.p_promo_id,
        d.d_year,
        SUM(ss.ss_ext_sales_price) AS total_sales,
        SUM(ss.ss_net_profit) AS total_profit,
        SUM(ss.ss_quantity) AS total_quantity,
        SUM(COALESCE(wr.wr_return_amt, 0)) AS total_return_amt,
        SUM(COALESCE(wr.wr_return_quantity, 0)) AS total_return_qty,
        SUM(ss.ss_ext_sales_price) - SUM(COALESCE(wr.wr_return_amt, 0)) AS net_gain
    FROM date_dim d
    JOIN store_sales ss ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
    JOIN web_returns wr ON wr.wr_returned_date_sk = d.d_date_sk
    WHERE d.d_year = 2001
      AND d.d_month_seq BETWEEN 1200 AND 1240
      AND p.p_channel_event = 'Y'
      AND p.p_channel_catalog = 'N'
      AND s.s_state = 'CA'
      AND s.s_tax_percentage > 0.05
      AND s.s_closed_date_sk IS NULL
      AND d.d_current_year = 'Y'
    GROUP BY s.s_store_id, s.s_state, p.p_promo_id, d.d_year
)
SELECT
    s_state,
    p_promo_id,
    COUNT(DISTINCT s_store_id) AS store_count,
    SUM(total_sales) AS sum_sales,
    SUM(total_profit) AS sum_profit,
    SUM(net_gain) AS sum_net_gain,
    AVG(total_profit) AS avg_profit_per_store,
    AVG(net_gain) AS avg_net_gain_per_store
FROM sales_agg
GROUP BY s_state, p_promo_id
HAVING SUM(total_sales) > 1000000
ORDER BY sum_profit DESC
LIMIT 50

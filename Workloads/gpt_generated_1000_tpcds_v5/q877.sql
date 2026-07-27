WITH sales_returns AS (
    SELECT
        ss.ss_ticket_number,
        ss.ss_sold_date_sk,
        ss.ss_quantity,
        ss.ss_ext_sales_price,
        ss.ss_net_profit,
        td.t_hour,
        td.t_am_pm,
        p.p_channel_radio,
        hd.hd_buy_potential,
        s.s_store_name AS store_name,
        sr.sr_return_quantity,
        sr.sr_return_amt,
        CASE WHEN p.p_channel_radio = 'Y' THEN ss.ss_ext_sales_price * 1.1 ELSE ss.ss_ext_sales_price END AS adjusted_sales_price
    FROM store_sales ss
    JOIN time_dim td
        ON ss.ss_sold_time_sk = td.t_time_sk
    JOIN promotion p
        ON ss.ss_promo_sk = p.p_promo_sk
    JOIN household_demographics hd
        ON ss.ss_hdemo_sk = hd.hd_demo_sk
    JOIN store s
        ON ss.ss_store_sk = s.s_store_sk
    LEFT JOIN store_returns sr
        ON sr.sr_ticket_number = ss.ss_ticket_number
    LEFT JOIN time_dim td_ret
        ON sr.sr_return_time_sk = td_ret.t_time_sk
    LEFT JOIN store s_ret
        ON sr.sr_store_sk = s_ret.s_store_sk
    LEFT JOIN household_demographics hd_ret
        ON sr.sr_hdemo_sk = hd_ret.hd_demo_sk
    LEFT JOIN store_sales ss_ret_item
        ON sr.sr_item_sk = ss_ret_item.ss_item_sk
    WHERE td.t_hour BETWEEN 9 AND 18
)
SELECT
    store_name,
    p_channel_radio,
    hd_buy_potential,
    t_hour,
    SUM(ss_quantity) AS total_quantity_sold,
    SUM(adjusted_sales_price) AS total_adjusted_sales,
    SUM(sr_return_quantity) AS total_return_quantity,
    SUM(sr_return_amt) AS total_return_amount,
    (SUM(ss_net_profit) - SUM(sr_return_amt)) AS net_profit_after_returns,
    RANK() OVER (PARTITION BY store_name ORDER BY SUM(adjusted_sales_price) DESC) AS sales_rank,
    SUM(SUM(adjusted_sales_price)) OVER (PARTITION BY store_name) AS cumulative_sales_by_store
FROM sales_returns
GROUP BY store_name, p_channel_radio, hd_buy_potential, t_hour
HAVING SUM(ss_quantity) > 0
ORDER BY total_adjusted_sales DESC
LIMIT 100

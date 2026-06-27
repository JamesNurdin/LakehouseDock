WITH sales_and_returns AS (
    SELECT
        ss.ss_store_sk,
        ss.ss_sold_time_sk,
        ss.ss_hdemo_sk,
        ss.ss_net_profit,
        ss.ss_quantity,
        ss.ss_ext_sales_price,
        ss.ss_promo_sk,
        r.sr_net_loss,
        r.sr_return_amt
    FROM store_sales ss
    LEFT JOIN store_returns r
        ON ss.ss_ticket_number = r.sr_ticket_number
        AND ss.ss_item_sk = r.sr_item_sk
)
SELECT
    s.s_store_id,
    s.s_store_name,
    t.t_hour,
    hd.hd_buy_potential,
    COUNT(*) AS sales_transactions,
    SUM(sales_and_returns.ss_net_profit) AS total_sales_profit,
    COALESCE(SUM(sales_and_returns.sr_net_loss), 0) AS total_return_loss,
    SUM(sales_and_returns.ss_net_profit) - COALESCE(SUM(sales_and_returns.sr_net_loss), 0) AS net_profit_after_returns,
    SUM(sales_and_returns.ss_quantity) AS total_quantity_sold,
    SUM(sales_and_returns.ss_ext_sales_price) AS total_sales_amount,
    SUM(CASE WHEN sales_and_returns.ss_promo_sk IS NOT NULL THEN 1 ELSE 0 END) * 1.0 / COUNT(*) AS promo_rate,
    AVG(sales_and_returns.ss_ext_sales_price / NULLIF(sales_and_returns.ss_quantity, 0)) AS avg_price_per_item
FROM sales_and_returns
JOIN store s
    ON sales_and_returns.ss_store_sk = s.s_store_sk
JOIN time_dim t
    ON sales_and_returns.ss_sold_time_sk = t.t_time_sk
JOIN household_demographics hd
    ON sales_and_returns.ss_hdemo_sk = hd.hd_demo_sk
GROUP BY
    s.s_store_id,
    s.s_store_name,
    t.t_hour,
    hd.hd_buy_potential
ORDER BY
    net_profit_after_returns DESC
LIMIT 100

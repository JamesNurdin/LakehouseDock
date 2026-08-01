WITH sales_returns AS (
    SELECT
        ss.ss_store_sk,
        ss.ss_ticket_number,
        s.s_store_id,
        s.s_city,
        s.s_state,
        i.i_category,
        i.i_current_price,
        ss.ss_net_paid_inc_tax,
        ss.ss_net_profit,
        COALESCE(sr.sr_return_amt, 0) AS sr_return_amt,
        sr.sr_return_quantity,
        inv.inv_quantity_on_hand,
        td_sold.t_hour AS sale_hour,
        td_return.t_hour AS return_hour
    FROM store_sales ss
    JOIN store s
        ON ss.ss_store_sk = s.s_store_sk
    JOIN customer_demographics cd
        ON ss.ss_cdemo_sk = cd.cd_demo_sk
    JOIN item i
        ON ss.ss_item_sk = i.i_item_sk
    JOIN time_dim td_sold
        ON ss.ss_sold_time_sk = td_sold.t_time_sk
    JOIN inventory inv
        ON inv.inv_item_sk = i.i_item_sk
    LEFT JOIN store_returns sr
        ON sr.sr_ticket_number = ss.ss_ticket_number
           AND sr.sr_item_sk = ss.ss_item_sk
           AND sr.sr_store_sk = s.s_store_sk
    LEFT JOIN time_dim td_return
        ON sr.sr_return_time_sk = td_return.t_time_sk
    WHERE
        ss.ss_net_paid_inc_tax > 1000
        AND i.i_current_price BETWEEN 100 AND 5000
        AND cd.cd_credit_rating = 'Good'
        AND s.s_state = 'CA'
        AND inv.inv_quantity_on_hand > 50
        AND td_sold.t_hour BETWEEN 9 AND 17
)
SELECT
    s_store_id,
    s_city,
    i_category,
    COUNT(DISTINCT ss_ticket_number) AS num_transactions,
    SUM(ss_net_paid_inc_tax) AS total_sales_inc_tax,
    SUM(ss_net_profit) AS total_profit,
    SUM(sr_return_amt) AS total_return_amount,
    AVG(inv_quantity_on_hand) AS avg_inventory_on_hand,
    COUNT(CASE WHEN sr_return_quantity > 0 THEN 1 END) AS return_count,
    (SELECT AVG(ss_net_profit) FROM store_sales) AS overall_avg_profit
FROM sales_returns
WHERE EXISTS (
    SELECT 1
    FROM store_returns sr2
    WHERE sr2.sr_store_sk = sales_returns.ss_store_sk
      AND sr2.sr_return_amt > 500
)
GROUP BY
    s_store_id,
    s_city,
    i_category
ORDER BY total_sales_inc_tax DESC
LIMIT 100

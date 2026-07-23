SELECT
    cc.cc_name,
    d.d_year,
    hd.hd_buy_potential,
    p.p_promo_name,
    COUNT(DISTINCT ss.ss_ticket_number) AS num_transactions,
    SUM(ss.ss_ext_sales_price) AS total_sales,
    SUM(ss.ss_net_profit) AS total_net_profit,
    AVG(ss.ss_sales_price) AS avg_sales_price,
    SUM(inv.inv_quantity_on_hand) AS total_inventory_on_hand,
    CASE
        WHEN SUM(ss.ss_net_profit) > (SELECT AVG(ss2.ss_net_profit) FROM store_sales ss2) THEN 'AboveAvgProfit'
        ELSE 'BelowAvgProfit'
    END AS profit_category,
    CASE
        WHEN SUM(ss.ss_ext_sales_price) > 100000 THEN 'LargeSales'
        ELSE 'SmallSales'
    END AS sales_size
FROM
    store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
    JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
    JOIN call_center cc ON cc.cc_open_date_sk = d.d_date_sk
    JOIN inventory inv ON inv.inv_date_sk = d.d_date_sk
    JOIN web_returns wr ON wr.wr_returned_date_sk = d.d_date_sk
        AND wr.wr_refunded_hdemo_sk = hd.hd_demo_sk
WHERE
    cc.cc_market_manager = 'Mark Camp'
    AND d.d_year = 2002
    AND inv.inv_quantity_on_hand > 500
    AND ss.ss_sales_price > 100.00
    AND wr.wr_fee > 50.00
GROUP BY
    cc.cc_name,
    d.d_year,
    hd.hd_buy_potential,
    p.p_promo_name
HAVING
    SUM(ss.ss_net_profit) > 5000
ORDER BY
    total_net_profit DESC
LIMIT 100

WITH filtered_sales AS (
    SELECT
        ss.ss_sold_date_sk,
        ss.ss_sold_time_sk,
        ss.ss_item_sk,
        ss.ss_customer_sk,
        ss.ss_hdemo_sk,
        ss.ss_store_sk,
        ss.ss_promo_sk,
        ss.ss_quantity,
        ss.ss_ext_sales_price,
        ss.ss_ext_discount_amt,
        ss.ss_net_profit
    FROM store_sales ss
    WHERE ss.ss_quantity > 0
)
SELECT
    s.s_store_name,
    i.i_category,
    td.t_hour,
    SUM(fs.ss_ext_sales_price) AS total_sales,
    AVG(fs.ss_ext_discount_amt) AS avg_discount,
    COUNT(DISTINCT fs.ss_customer_sk) AS unique_customers,
    MAX(fs.ss_net_profit) AS max_profit,
    (
        SELECT AVG(i2.i_current_price)
        FROM item i2
        WHERE i2.i_category = i.i_category
    ) AS avg_category_price
FROM filtered_sales fs
JOIN time_dim td
    ON fs.ss_sold_time_sk = td.t_time_sk
JOIN item i
    ON fs.ss_item_sk = i.i_item_sk
JOIN household_demographics hd
    ON fs.ss_hdemo_sk = hd.hd_demo_sk
JOIN store s
    ON fs.ss_store_sk = s.s_store_sk
JOIN promotion p
    ON fs.ss_promo_sk = p.p_promo_sk
JOIN inventory inv
    ON i.i_item_sk = inv.inv_item_sk
WHERE
    td.t_am_pm = 'PM'
    AND td.t_minute = 5
    AND i.i_formulation LIKE '%goldenrod%'
    AND hd.hd_buy_potential = '5001-10000'
    AND s.s_state = 'CA'
    AND EXISTS (
        SELECT 1 FROM inventory inv2
        WHERE inv2.inv_item_sk = i.i_item_sk
          AND inv2.inv_quantity_on_hand > 0
    )
GROUP BY
    s.s_store_name,
    i.i_category,
    td.t_hour
ORDER BY total_sales DESC
LIMIT 100

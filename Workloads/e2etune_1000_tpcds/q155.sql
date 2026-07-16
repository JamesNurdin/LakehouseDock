WITH inv_filtered AS (
    SELECT inv_item_sk, inv_quantity_on_hand
    FROM inventory
    WHERE inv_date_sk = 2451046
      AND inv_quantity_on_hand > 200
),
sales_detail AS (
    SELECT
        ss.ss_store_sk,
        ss.ss_item_sk,
        ss.ss_sold_date_sk,
        ss.ss_net_profit,
        ss.ss_quantity,
        ss.ss_ext_discount_amt,
        ss.ss_promo_sk,
        i.i_class,
        i.i_category,
        i.i_brand,
        s.s_state,
        s.s_market_id,
        p.p_discount_active
    FROM store_sales ss
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
)
SELECT
    sd.s_state,
    sd.i_class,
    SUM(sd.ss_net_profit) AS total_net_profit,
    SUM(sd.ss_quantity) AS total_quantity_sold,
    AVG(sd.ss_ext_discount_amt) AS avg_discount_amount,
    COUNT(DISTINCT sd.ss_promo_sk) AS distinct_promotions,
    RANK() OVER (ORDER BY SUM(sd.ss_net_profit) DESC) AS profit_rank
FROM sales_detail sd
JOIN inv_filtered inv ON sd.ss_item_sk = inv.inv_item_sk
WHERE sd.ss_sold_date_sk BETWEEN 2450815 AND 2451053
  AND sd.p_discount_active = 'Y'
GROUP BY sd.s_state, sd.i_class
HAVING SUM(sd.ss_net_profit) > 0
ORDER BY total_net_profit DESC
LIMIT 10

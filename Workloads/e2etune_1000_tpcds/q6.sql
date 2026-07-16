WITH sales_union AS (
    SELECT
        ss.ss_net_profit AS net_profit,
        ss.ss_quantity AS quantity,
        ss.ss_coupon_amt AS coupon_amt,
        ss.ss_sold_date_sk AS sold_date_sk,
        ss.ss_promo_sk AS promo_sk,
        ss.ss_customer_sk AS customer_sk,
        ss.ss_item_sk AS item_sk,
        ss.ss_hdemo_sk AS hdemo_sk
    FROM store_sales ss
    UNION ALL
    SELECT
        cs.cs_net_profit AS net_profit,
        cs.cs_quantity AS quantity,
        cs.cs_coupon_amt AS coupon_amt,
        cs.cs_sold_date_sk AS sold_date_sk,
        cs.cs_promo_sk AS promo_sk,
        cs.cs_bill_customer_sk AS customer_sk,
        cs.cs_item_sk AS item_sk,
        cs.cs_bill_hdemo_sk AS hdemo_sk
    FROM catalog_sales cs
)
SELECT
    i.i_category AS category,
    p.p_promo_name AS promo_name,
    SUM(su.net_profit) AS total_net_profit,
    SUM(su.quantity) AS total_quantity,
    AVG(su.coupon_amt) AS avg_coupon_amount,
    COUNT(DISTINCT su.customer_sk) AS distinct_customers,
    COUNT(*) AS total_transactions
FROM sales_union su
JOIN item i ON su.item_sk = i.i_item_sk
JOIN promotion p ON su.promo_sk = p.p_promo_sk
JOIN household_demographics hd ON su.hdemo_sk = hd.hd_demo_sk
WHERE su.sold_date_sk BETWEEN 2450815 AND 2450997
  AND hd.hd_income_band_sk BETWEEN 1 AND 5
  AND p.p_channel_email = 'Y'
GROUP BY i.i_category, p.p_promo_name
HAVING SUM(su.net_profit) > 1000
ORDER BY total_net_profit DESC
LIMIT 10

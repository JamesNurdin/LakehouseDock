WITH sales_items AS (
    SELECT
        cs.cs_order_number,
        cs.cs_net_paid,
        cs.cs_net_profit,
        cs.cs_bill_customer_sk,
        i.i_category,
        i.i_item_desc,
        p.p_promo_name,
        p.p_channel_tv,
        lw.first_word
    FROM catalog_sales cs
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
    LEFT JOIN LATERAL (
        SELECT regexp_extract(i.i_item_desc, '^([^ ]+)') AS first_word
    ) lw ON true
    WHERE regexp_like(i.i_item_desc, '(?i)tv|radio')
      AND i.i_item_desc LIKE '%Large%'
      AND p.p_channel_tv = 'Y'
)
SELECT
    si.cs_order_number,
    CONCAT(si.i_category, ':', si.p_promo_name) AS category_promo,
    CASE
        WHEN si.cs_net_profit > (SELECT avg(cs2.cs_net_profit) FROM catalog_sales cs2) THEN 'Above Avg'
        ELSE 'Below Avg'
    END AS profit_indicator,
    si.first_word,
    SUM(si.cs_net_paid) AS total_net_paid,
    COUNT(*) AS rows_per_order
FROM sales_items si
WHERE si.cs_bill_customer_sk IN (
        SELECT c.c_customer_sk FROM customer c WHERE c.c_preferred_cust_flag = 'Y'
    )
  AND EXISTS (
        SELECT 1
        FROM store_returns sr
        JOIN item i2 ON sr.sr_item_sk = i2.i_item_sk
        WHERE sr.sr_customer_sk = si.cs_bill_customer_sk
          AND i2.i_category = si.i_category
    )
GROUP BY
    si.cs_order_number,
    si.i_category,
    si.p_promo_name,
    si.first_word,
    si.cs_net_profit
ORDER BY total_net_paid DESC
LIMIT 100

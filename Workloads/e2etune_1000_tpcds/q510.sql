WITH sales_agg AS (
    SELECT
        i.i_brand AS brand,
        i.i_category AS category,
        p.p_promo_name AS promo_name,
        SUM(cs.cs_net_profit) AS total_net_profit,
        SUM(cs.cs_ext_sales_price) AS total_sales,
        AVG(cs.cs_ext_discount_amt) AS avg_discount,
        SUM(cs.cs_quantity) AS total_quantity
    FROM catalog_sales cs
    JOIN customer c ON cs.cs_bill_customer_sk = c.c_customer_sk
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
    JOIN inventory inv ON i.i_item_sk = inv.inv_item_sk
    WHERE cs.cs_sold_date_sk BETWEEN 2450820 AND 2450826
      AND inv.inv_quantity_on_hand > 0
      AND p.p_discount_active = 'Y'
    GROUP BY i.i_brand, i.i_category, p.p_promo_name
    HAVING SUM(cs.cs_quantity) > 100
)
SELECT
    brand,
    category,
    promo_name,
    total_net_profit,
    total_sales,
    avg_discount,
    total_quantity,
    RANK() OVER (PARTITION BY brand ORDER BY total_net_profit DESC) AS brand_promo_rank
FROM sales_agg
ORDER BY total_net_profit DESC
LIMIT 10

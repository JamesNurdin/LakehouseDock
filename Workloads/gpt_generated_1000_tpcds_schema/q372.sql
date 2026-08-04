WITH avg_profit AS (
    SELECT avg(ss_net_profit) AS avg_profit
    FROM store_sales
)
SELECT *
FROM (
    SELECT i.i_item_id,
           i.i_product_name,
           ss.ss_net_profit,
           'above' AS profit_category
    FROM store_sales ss
    RIGHT OUTER JOIN item i
        ON ss.ss_item_sk = i.i_item_sk
    LEFT JOIN promotion p
        ON ss.ss_promo_sk = p.p_promo_sk
    WHERE ss.ss_net_profit > (SELECT avg_profit FROM avg_profit)
      AND p.p_purpose = 'Unknown'

    UNION ALL

    SELECT i.i_item_id,
           i.i_product_name,
           ss.ss_net_profit,
           'below_or_equal' AS profit_category
    FROM store_sales ss
    RIGHT OUTER JOIN item i
        ON ss.ss_item_sk = i.i_item_sk
    WHERE ss.ss_net_profit <= (SELECT avg_profit FROM avg_profit)
       OR ss.ss_net_profit IS NULL
) AS combined
ORDER BY profit_category, i_item_id
OFFSET 10 ROWS FETCH NEXT 20 ROWS ONLY

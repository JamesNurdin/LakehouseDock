WITH sales_ranked AS (
    SELECT
        s.s_store_id,
        s.s_store_name,
        i.i_product_name,
        i.i_class,
        ss.ss_net_profit,
        ss.ss_ext_discount_amt,
        ROW_NUMBER() OVER (PARTITION BY s.s_store_id ORDER BY ss.ss_net_profit DESC) AS profit_rank
    FROM tpcds.store_sales ss
    JOIN tpcds.store s
        ON ss.ss_store_sk = s.s_store_sk
    JOIN tpcds.item i
        ON ss.ss_item_sk = i.i_item_sk
    WHERE ss.ss_net_profit > 1000
      AND ss.ss_wholesale_cost IN (21.27, 86.27, 79.71)
      AND i.i_class IN ('pants', 'dresses')
)
SELECT
    s_store_id,
    s_store_name,
    i_product_name,
    ss_net_profit,
    profit_rank
FROM sales_ranked
WHERE profit_rank <= 5

UNION ALL

SELECT
    s_store_id,
    s_store_name,
    i_product_name,
    ss_net_profit,
    profit_rank
FROM sales_ranked
WHERE ss_ext_discount_amt > 500
  AND i_class = 'dresses'

ORDER BY ss_net_profit DESC
LIMIT 100

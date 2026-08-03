WITH catalog_agg AS (
    SELECT
        i.i_item_id,
        i.i_item_sk,
        i.i_category,
        td.t_hour,
        SUM(cs.cs_ext_sales_price) AS total_sales,
        COUNT(cs.cs_order_number) AS order_cnt
    FROM catalog_sales cs
    JOIN time_dim td ON cs.cs_sold_time_sk = td.t_time_sk
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
    WHERE cs.cs_ext_sales_price > 1000
      AND td.t_hour BETWEEN 9 AND 17
    GROUP BY i.i_item_id, i.i_item_sk, i.i_category, td.t_hour
),
store_agg AS (
    SELECT
        i.i_item_id,
        i.i_item_sk,
        i.i_category,
        td.t_hour,
        SUM(ss.ss_ext_sales_price) AS total_sales,
        COUNT(ss.ss_ticket_number) AS order_cnt
    FROM store_sales ss
    JOIN time_dim td ON ss.ss_sold_time_sk = td.t_time_sk
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
    WHERE ss.ss_ext_sales_price > 1000
      AND td.t_hour BETWEEN 9 AND 17
    GROUP BY i.i_item_id, i.i_item_sk, i.i_category, td.t_hour
),
combined AS (
    SELECT * FROM catalog_agg
    UNION ALL
    SELECT * FROM store_agg
)
SELECT
    c.i_item_id,
    c.i_category,
    c.t_hour,
    SUM(c.total_sales) AS total_sales,
    SUM(c.order_cnt)   AS total_orders
FROM combined c
WHERE EXISTS (
    SELECT 1
    FROM promotion p
    WHERE p.p_item_sk = c.i_item_sk
      AND p.p_discount_active = 'Y'
)
GROUP BY c.i_item_id, c.i_category, c.t_hour
ORDER BY total_sales DESC
LIMIT 100

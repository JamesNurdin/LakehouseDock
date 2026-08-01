WITH sales_filtered AS (
    SELECT
        ss.ss_customer_sk,
        ss.ss_quantity,
        ss.ss_net_paid,
        ss.ss_net_profit,
        i.i_category,
        i.i_item_desc,
        s.s_store_name,
        c.c_email_address,
        t.t_hour
    FROM store_sales ss
    INNER JOIN item i
        ON ss.ss_item_sk = i.i_item_sk
    INNER JOIN customer c
        ON ss.ss_customer_sk = c.c_customer_sk
    INNER JOIN store s
        ON ss.ss_store_sk = s.s_store_sk
    INNER JOIN promotion p
        ON ss.ss_promo_sk = p.p_promo_sk
    INNER JOIN time_dim t
        ON ss.ss_sold_time_sk = t.t_time_sk
    WHERE regexp_like(i.i_item_desc, '(?i)large')
      AND regexp_like(c.c_email_address, '@gmail\\.com$')
      AND t.t_hour BETWEEN 9 AND 17
      AND p.p_discount_active = 'Y'
)
SELECT
    sales_filtered.s_store_name,
    sales_filtered.i_category,
    COUNT(DISTINCT sales_filtered.ss_customer_sk) AS distinct_customers,
    SUM(sales_filtered.ss_quantity) AS total_quantity,
    SUM(sales_filtered.ss_net_paid) AS total_net_paid,
    SUM(sales_filtered.ss_net_profit) AS total_net_profit,
    CONCAT('Store: ', SUBSTRING(sales_filtered.s_store_name, 1, 5), ' | Category: ', COALESCE(sales_filtered.i_category, 'All')) AS store_category_label
FROM sales_filtered
GROUP BY ROLLUP (sales_filtered.s_store_name, sales_filtered.i_category)
ORDER BY
    total_net_profit DESC,
    sales_filtered.s_store_name ASC,
    sales_filtered.i_category ASC
LIMIT 100

WITH sales_agg AS (
    SELECT
        store.s_store_id AS s_store_id,
        store.s_store_name AS s_store_name,
        promotion.p_promo_id AS p_promo_id,
        promotion.p_promo_name AS p_promo_name,
        SUM(store_sales.ss_ext_sales_price) AS total_sales,
        SUM(store_sales.ss_net_profit) AS total_net_profit,
        SUM(COALESCE(store_returns.sr_return_amt, 0)) AS total_returns,
        COUNT(DISTINCT store_sales.ss_ticket_number) AS distinct_tickets,
        CONCAT(MIN(customer.c_first_name), ' ', MIN(customer.c_last_name)) AS sample_customer_name,
        SUBSTRING(MIN(customer.c_last_name), 1, 3) AS last_name_prefix,
        REGEXP_EXTRACT(promotion.p_promo_name, '([A-Z]{2,5})', 1) AS promo_code
    FROM store_sales
    JOIN store
        ON store_sales.ss_store_sk = store.s_store_sk
    JOIN promotion
        ON store_sales.ss_promo_sk = promotion.p_promo_sk
    JOIN customer
        ON store_sales.ss_customer_sk = customer.c_customer_sk
    LEFT JOIN store_returns
        ON store_sales.ss_ticket_number = store_returns.sr_ticket_number
        AND store_sales.ss_item_sk = store_returns.sr_item_sk
    WHERE REGEXP_LIKE(store.s_store_name, 'Market|Store')
      AND REGEXP_LIKE(promotion.p_promo_name, '^Promo')
      AND customer.c_email_address LIKE '%@example.com'
    GROUP BY
        store.s_store_id,
        store.s_store_name,
        promotion.p_promo_id,
        promotion.p_promo_name
)
SELECT
    s_store_id,
    s_store_name,
    p_promo_id,
    p_promo_name,
    promo_code,
    total_sales,
    total_net_profit,
    total_returns,
    distinct_tickets,
    sample_customer_name,
    last_name_prefix,
    RANK() OVER (ORDER BY total_sales DESC) AS overall_sales_rank,
    ROW_NUMBER() OVER (PARTITION BY s_store_name ORDER BY total_sales DESC) AS store_sales_rank
FROM sales_agg
WHERE total_sales > 5000
ORDER BY total_sales DESC
LIMIT 100

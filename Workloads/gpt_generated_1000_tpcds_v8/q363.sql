WITH sampled_items AS (
    SELECT i_item_sk, i_manufact_id, i_product_name
    FROM item TABLESAMPLE BERNOULLI (10)
    WHERE regexp_like(i_product_name, '[A-Z]{3}')
),

store_sales_agg AS (
    SELECT
        si.i_manufact_id,
        SUM(ss.ss_ext_sales_price) AS store_sales_total,
        COUNT(DISTINCT ss.ss_ticket_number) AS store_orders
    FROM sampled_items si
    JOIN store_sales ss ON ss.ss_item_sk = si.i_item_sk
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    WHERE s.s_state LIKE 'A%'
    GROUP BY si.i_manufact_id
    HAVING SUM(ss.ss_ext_sales_price) > 5000
),

web_sales_agg AS (
    SELECT
        wi.i_manufact_id,
        SUM(ws.ws_ext_sales_price) AS web_sales_total,
        COUNT(DISTINCT ws.ws_order_number) AS web_orders
    FROM sampled_items wi
    JOIN web_sales ws ON ws.ws_item_sk = wi.i_item_sk
    JOIN web_site wsite ON ws.ws_web_site_sk = wsite.web_site_sk
    WHERE wsite.web_country = 'United States'
    GROUP BY wi.i_manufact_id
    HAVING SUM(ws.ws_ext_sales_price) > 5000
),

combined AS (
    SELECT
        sa.i_manufact_id,
        (sa.store_sales_total + wa.web_sales_total) AS total_sales,
        (sa.store_orders + wa.web_orders) AS total_orders
    FROM store_sales_agg sa
    JOIN web_sales_agg wa ON sa.i_manufact_id = wa.i_manufact_id
    WHERE (sa.store_sales_total + wa.web_sales_total) > 10000
),

order_intersect AS (
    SELECT ss_ticket_number AS order_id FROM store_sales
    INTERSECT
    SELECT ws_order_number AS order_id FROM web_sales
),

final AS (
    SELECT
        c.i_manufact_id,
        c.total_sales,
        c.total_orders,
        (SELECT COUNT(*) FROM customer WHERE regexp_like(c_email_address, '^.*@example\\.com$')) AS example_com_customers
    FROM combined c
    WHERE c.total_orders > (SELECT AVG(total_orders) FROM combined)
      AND EXISTS (SELECT 1 FROM order_intersect oi)
      AND EXISTS (
          SELECT 1 FROM customer cu
          WHERE substring(cu.c_last_name, 1, 1) = 'S'
            AND regexp_like(cu.c_email_address, '^.*@example\\.com$')
      )
)

SELECT DISTINCT
    i_manufact_id,
    total_sales,
    total_orders,
    example_com_customers
FROM final
UNION
SELECT DISTINCT
    i_manufact_id,
    total_sales,
    total_orders,
    example_com_customers
FROM final
WHERE regexp_like(cast(total_sales AS varchar), '^\\d{5,}$')
LIMIT 100

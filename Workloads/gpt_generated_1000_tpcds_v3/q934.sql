WITH store_sales_agg AS (
    SELECT
        'store' AS entity_type,
        s.s_store_id AS entity_id,
        d.d_year AS year,
        SUM(ss.ss_net_profit) AS metric_value,
        (SELECT COUNT(*) FROM store) AS total_stores
    FROM store_sales ss
    INNER JOIN store s
        ON ss.ss_store_sk = s.s_store_sk
    INNER JOIN date_dim d
        ON ss.ss_sold_date_sk = d.d_date_sk
    INNER JOIN customer c
        ON ss.ss_customer_sk = c.c_customer_sk
    WHERE d.d_year = 2001
      AND EXISTS (
          SELECT 1
          FROM customer_address ca
          WHERE ca.ca_address_sk = c.c_current_addr_sk
            AND ca.ca_state = 'CA'
      )
    GROUP BY s.s_store_id, d.d_year
),
web_page_agg AS (
    SELECT
        'customer' AS entity_type,
        c.c_customer_id AS entity_id,
        d.d_year AS year,
        CAST(SUM(wp.wp_char_count) AS decimal(15,2)) AS metric_value,
        (SELECT COUNT(*) FROM store) AS total_stores
    FROM web_page wp
    INNER JOIN customer c
        ON wp.wp_customer_sk = c.c_customer_sk
    INNER JOIN date_dim d
        ON wp.wp_creation_date_sk = d.d_date_sk
    WHERE d.d_year = 2001
      AND c.c_preferred_cust_flag = 'Y'
      AND c.c_customer_sk IN (
          SELECT ss2.ss_customer_sk
          FROM store_sales ss2
          INNER JOIN date_dim d2
              ON ss2.ss_sold_date_sk = d2.d_date_sk
          WHERE d2.d_year = 2001
      )
    GROUP BY c.c_customer_id, d.d_year
)
SELECT
    entity_type,
    entity_id,
    year,
    metric_value,
    total_stores
FROM store_sales_agg
UNION ALL
SELECT
    entity_type,
    entity_id,
    year,
    metric_value,
    total_stores
FROM web_page_agg
ORDER BY metric_value DESC
LIMIT 100

WITH filtered_items AS (
    SELECT 
        i.i_item_sk,
        i.i_item_id,
        i.i_product_name,
        i.i_brand,
        CONCAT(i.i_brand, ' ', i.i_product_name) AS brand_product_concat,
        SUBSTR(i.i_product_name, 1, 10) AS product_name_prefix,
        CASE 
            WHEN REGEXP_LIKE(i.i_item_desc, '[0-9]{3}') THEN 'HAS_NUM'
            ELSE 'NO_NUM'
        END AS desc_num_flag
    FROM item i
    WHERE REGEXP_LIKE(i.i_item_desc, '.*(BRUSH|PAINT).*')
      AND i.i_product_name LIKE '%Pro%'
),

sales_agg AS (
    SELECT 
        fi.i_item_sk,
        COALESCE(SUM(cs.cs_net_profit), 0) AS total_cs_profit,
        COALESCE(SUM(ss.ss_net_profit), 0) AS total_ss_profit,
        COUNT(DISTINCT cs.cs_order_number) AS cs_orders,
        COUNT(DISTINCT ss.ss_ticket_number) AS ss_tickets,
        CASE 
            WHEN COALESCE(SUM(cs.cs_net_profit), 0) + COALESCE(SUM(ss.ss_net_profit), 0) > 100000 THEN 'HIGH'
            WHEN COALESCE(SUM(cs.cs_net_profit), 0) + COALESCE(SUM(ss.ss_net_profit), 0) > 50000 THEN 'MEDIUM'
            ELSE 'LOW'
        END AS profit_category
    FROM filtered_items fi
    LEFT JOIN catalog_sales cs ON cs.cs_item_sk = fi.i_item_sk
    LEFT JOIN store_sales ss ON ss.ss_item_sk = fi.i_item_sk
    LEFT JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    WHERE d.d_year = 2002
    GROUP BY fi.i_item_sk
),

ctas_items AS (
    SELECT cs.cs_item_sk AS i_item_sk
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    WHERE d.d_year = 2002
      AND cs.cs_quantity > 5
),

ws_items AS (
    SELECT ws.ws_item_sk AS i_item_sk
    FROM web_sales ws
    JOIN date_dim d2 ON ws.ws_sold_date_sk = d2.d_date_sk
    WHERE d2.d_year = 2002
      AND ws.ws_quantity > 5
),

intersect_items AS (
    SELECT i_item_sk FROM ctas_items
    INTERSECT
    SELECT i_item_sk FROM ws_items
),

final_result AS (
    SELECT 
        fi.i_item_id,
        fi.i_product_name,
        fi.brand_product_concat,
        fi.product_name_prefix,
        COALESCE(sa.total_cs_profit, 0) AS total_cs_profit,
        COALESCE(sa.total_ss_profit, 0) AS total_ss_profit,
        sa.profit_category,
        (
            SELECT COUNT(*)
            FROM catalog_returns cr
            WHERE cr.cr_item_sk = fi.i_item_sk
              AND cr.cr_return_quantity > 0
        ) AS return_count,
        CASE 
            WHEN EXISTS (
                SELECT 1
                FROM catalog_returns cr2
                WHERE cr2.cr_item_sk = fi.i_item_sk
                  AND cr2.cr_return_amount > 0
            ) THEN 'HAS_RETURNS'
            ELSE 'NO_RETURNS'
        END AS return_flag
    FROM filtered_items fi
    LEFT JOIN sales_agg sa ON sa.i_item_sk = fi.i_item_sk
    WHERE fi.i_item_sk IN (SELECT i_item_sk FROM intersect_items)
)
SELECT 
    i_item_id,
    i_product_name,
    brand_product_concat,
    product_name_prefix,
    total_cs_profit,
    total_ss_profit,
    profit_category,
    return_count,
    return_flag
FROM final_result
ORDER BY profit_category DESC, total_cs_profit DESC
LIMIT 100

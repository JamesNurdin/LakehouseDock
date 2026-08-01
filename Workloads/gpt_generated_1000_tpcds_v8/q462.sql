WITH intersect_items AS (
        SELECT cs.cs_item_sk
        FROM catalog_sales cs
        JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
        WHERE regexp_like(p.p_promo_name, 'Black Friday')
        INTERSECT
        SELECT ws.ws_item_sk
        FROM web_sales ws
        JOIN promotion p2 ON ws.ws_promo_sk = p2.p_promo_sk
        WHERE regexp_like(p2.p_promo_name, 'Black Friday')
    ),
    except_items AS (
        SELECT ws.ws_item_sk
        FROM web_sales ws
        JOIN promotion p3 ON ws.ws_promo_sk = p3.p_promo_sk
        WHERE p3.p_channel_press = 'N'
        EXCEPT
        SELECT cs.cs_item_sk
        FROM catalog_sales cs
        JOIN promotion p4 ON cs.cs_promo_sk = p4.p_promo_sk
        WHERE p4.p_channel_press = 'N'
    ),
    agg AS (
        SELECT
            p.p_promo_name,
            d.d_year,
            s.s_store_id,
            SUM(cs.cs_net_profit) AS total_net_profit,
            COUNT(DISTINCT cs.cs_item_sk) AS distinct_items_sold,
            COUNT(DISTINCT it.cs_item_sk) AS intersect_item_count,
            COUNT(DISTINCT et.ws_item_sk) AS except_item_count,
            CONCAT(p.p_channel_email, '_', CAST(p.p_promo_id AS varchar)) AS promo_contact_key,
            SUBSTRING(p.p_promo_name FROM 1 FOR 10) AS promo_name_prefix
        FROM
            date_dim d
            RIGHT OUTER JOIN store s ON s.s_closed_date_sk = d.d_date_sk
            LEFT JOIN (SELECT * FROM catalog_sales TABLESAMPLE BERNOULLI (10)) cs ON cs.cs_sold_date_sk = d.d_date_sk
            LEFT JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
            LEFT JOIN intersect_items it ON cs.cs_item_sk = it.cs_item_sk
            LEFT JOIN except_items et ON cs.cs_item_sk = et.ws_item_sk
        WHERE
            p.p_channel_email LIKE '%@example.com'
            AND regexp_extract(p.p_promo_name, '(\\d{4})', 1) = CAST(d.d_year AS varchar)
            AND EXISTS (
                SELECT 1
                FROM catalog_returns cr
                WHERE cr.cr_order_number = cs.cs_order_number
                  AND cr.cr_return_quantity > 0
            )
        GROUP BY
            p.p_promo_name,
            d.d_year,
            s.s_store_id,
            p.p_channel_email,
            p.p_promo_id
    )
SELECT *
FROM agg
ORDER BY total_net_profit DESC
LIMIT 100

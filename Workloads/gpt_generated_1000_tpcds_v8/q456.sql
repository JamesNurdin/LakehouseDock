WITH sampled_ws AS (
    SELECT *
    FROM web_sales
    TABLESAMPLE BERNOULLI (10)
),
base AS (
    SELECT
        ws.ws_order_number,
        ws.ws_sales_price,
        ws.ws_quantity,
        d.d_year,
        i.i_category,
        s.s_store_name,
        site.web_name,
        (
            SELECT avg(ws2.ws_sales_price)
            FROM web_sales ws2
            WHERE ws2.ws_item_sk = i.i_item_sk
        ) AS category_avg_price
    FROM sampled_ws ws
    JOIN date_dim d
        ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN item i
        ON ws.ws_item_sk = i.i_item_sk
    LEFT JOIN store s
        ON s.s_closed_date_sk = d.d_date_sk
    JOIN web_site site
        ON ws.ws_web_site_sk = site.web_site_sk
    WHERE d.d_year = 2001
      AND i.i_current_price > 20
      AND ws.ws_sales_price BETWEEN 5 AND 50
),
filtered AS (
    SELECT *
    FROM base b
    WHERE EXISTS (
        SELECT 1
        FROM store s2
        WHERE s2.s_store_name = b.s_store_name
          AND s2.s_state = 'CA'
    )
),
union_set AS (
    SELECT ws_order_number FROM filtered
    UNION
    SELECT ws_order_number FROM filtered WHERE ws_quantity > 5
),
except_set AS (
    SELECT ws_order_number FROM filtered
    EXCEPT
    SELECT ws_order_number FROM filtered WHERE ws_quantity = 1
),
final AS (
    SELECT
        f.ws_order_number,
        f.ws_sales_price,
        f.ws_quantity,
        f.d_year,
        f.i_category,
        f.s_store_name,
        f.web_name,
        f.category_avg_price,
        RANK() OVER (PARTITION BY f.d_year ORDER BY f.ws_sales_price DESC) AS sales_price_rank,
        ROW_NUMBER() OVER (ORDER BY f.ws_sales_price DESC) AS overall_row_num
    FROM filtered f
    WHERE f.ws_order_number IN (SELECT ws_order_number FROM union_set)
      AND f.ws_order_number NOT IN (SELECT ws_order_number FROM except_set)
)
SELECT
    ws_order_number,
    ws_sales_price,
    ws_quantity,
    d_year,
    i_category,
    s_store_name,
    web_name,
    category_avg_price,
    sales_price_rank,
    overall_row_num
FROM final
ORDER BY sales_price_rank, overall_row_num
LIMIT 100

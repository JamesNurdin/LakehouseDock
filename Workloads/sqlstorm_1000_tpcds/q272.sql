WITH date_joined AS (
    SELECT d_date_sk, d_year
    FROM date_dim d
    WHERE d_year BETWEEN 2000 AND 2002
),
sales AS (
    SELECT
        ss_sold_date_sk AS sold_date_sk,
        ss_item_sk AS item_sk,
        ss_store_sk AS store_sk,
        ss_quantity AS quantity,
        ss_net_profit AS net_profit,
        ss_promo_sk AS promo_sk,
        'store' AS sales_source
    FROM store_sales ss
    WHERE ss_quantity > 0
    UNION ALL
    SELECT
        cs_sold_date_sk,
        cs_item_sk,
        NULL,
        cs_quantity,
        cs_net_profit,
        cs_promo_sk,
        'catalog'
    FROM catalog_sales cs
    WHERE cs_quantity > 0
),
returns AS (
    SELECT
        sr_returned_date_sk AS return_date_sk,
        sr_item_sk AS item_sk,
        sr_store_sk AS store_sk,
        sr_return_quantity AS quantity,
        -sr_net_loss AS net_profit,
        'store_return' AS return_source
    FROM store_returns sr
    UNION ALL
    SELECT
        cr_returned_date_sk,
        cr_item_sk,
        NULL,
        cr_return_quantity,
        -cr_net_loss,
        'catalog_return'
    FROM catalog_returns cr
    UNION ALL
    SELECT
        wr_returned_date_sk,
        wr_item_sk,
        NULL,
        wr_return_quantity,
        -wr_net_loss,
        'web_return'
    FROM web_returns wr
),
combined AS (
    SELECT
        COALESCE(s.sold_date_sk, r.return_date_sk) AS date_sk,
        COALESCE(s.item_sk, r.item_sk) AS item_sk,
        COALESCE(s.store_sk, r.store_sk) AS store_sk,
        COALESCE(s.quantity, 0) - COALESCE(r.quantity, 0) AS net_quantity,
        COALESCE(s.net_profit, 0) + COALESCE(r.net_profit, 0) AS net_profit,
        COALESCE(s.sales_source, r.return_source) AS source,
        COALESCE(s.promo_sk, NULL) AS promo_sk
    FROM sales s
    FULL OUTER JOIN returns r
        ON s.sold_date_sk = r.return_date_sk
        AND s.item_sk = r.item_sk
        AND (s.store_sk = r.store_sk OR (s.store_sk IS NULL AND r.store_sk IS NULL))
),
item_details AS (
    SELECT
        i_item_sk,
        i_product_name,
        i_brand,
        i_category,
        COALESCE(i_color, 'UNKNOWN') AS color,
        i_current_price
    FROM item i
),
store_details AS (
    SELECT
        s_store_sk,
        s_store_name,
        s_city,
        s_state,
        s_country,
        s_gmt_offset
    FROM store
),
promo_details AS (
    SELECT
        p_promo_sk,
        p_promo_name,
        p_discount_active,
        p_channel_email,
        p_channel_catalog,
        CASE WHEN p_discount_active = 'Y' THEN p_cost ELSE 0 END AS active_cost
    FROM promotion p
    WHERE p_discount_active IS NOT NULL
),
sales_agg AS (
    SELECT
        dj.d_year,
        COALESCE(sd.s_store_name, 'ALL_STORES') AS store_name,
        id.i_category,
        id.i_brand,
        id.i_product_name,
        SUM(c.net_quantity) AS total_quantity,
        SUM(c.net_profit) AS total_profit,
        AVG(id.i_current_price) AS avg_item_price,
        COUNT(DISTINCT c.item_sk) AS distinct_items_sold,
        CASE WHEN SUM(c.net_quantity) = 0 THEN NULL ELSE SUM(c.net_profit) / SUM(c.net_quantity) END AS profit_per_unit,
        MAX(pad.active_cost) FILTER (WHERE c.promo_sk = pad.p_promo_sk) AS max_active_promo_cost,
        ROW_NUMBER() OVER (
            PARTITION BY dj.d_year, COALESCE(sd.s_store_name, 'ALL_STORES')
            ORDER BY SUM(c.net_profit) DESC
        ) AS profit_rank,
        CONCAT('Store: ', COALESCE(sd.s_store_name, 'UNKNOWN'), ' | Item: ', COALESCE(id.i_product_name, 'UNKNOWN'), ' | Year: ', CAST(dj.d_year AS VARCHAR)) AS description,
        CASE
            WHEN (SUM(c.net_profit) > 0 AND SUM(c.net_quantity) > 0) THEN 'POS'
            WHEN (SUM(c.net_profit) < 0 AND SUM(c.net_quantity) > 0) THEN 'NEG'
            ELSE 'ZERO_OR_NULL'
        END AS profit_status
    FROM combined c
    LEFT JOIN date_joined dj ON c.date_sk = dj.d_date_sk
    LEFT JOIN item_details id ON c.item_sk = id.i_item_sk
    LEFT JOIN store_details sd ON c.store_sk = sd.s_store_sk
    LEFT JOIN promo_details pad ON c.promo_sk = pad.p_promo_sk
    GROUP BY GROUPING SETS (
        (dj.d_year, sd.s_store_name, id.i_category, id.i_brand, id.i_product_name),
        (dj.d_year, sd.s_store_name, id.i_category, id.i_brand),
        (dj.d_year, sd.s_store_name),
        (dj.d_year)
    )
    HAVING SUM(c.net_quantity) > 0
       AND COALESCE(SUM(c.net_profit), 0) <> 0
       AND NOT (dj.d_year IS NULL AND sd.s_store_name IS NULL)
),
final AS (
    SELECT
        *,
        SUM(total_profit) OVER (
            PARTITION BY d_year
            ORDER BY profit_rank
            ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
        ) AS cumulative_profit,
        (SELECT MAX(total_profit)
         FROM sales_agg sa2
         WHERE sa2.d_year = sales_agg.d_year
           AND sa2.i_category = sales_agg.i_category) AS category_year_max_profit,
        CASE
            WHEN REGEXP_LIKE(description, '.*Store:.*NY.*') THEN 'NY_STORE'
            ELSE 'OTHER_STORE'
        END AS store_region_flag
    FROM sales_agg
)
SELECT *
FROM final
WHERE profit_rank <= 5
ORDER BY d_year DESC, profit_rank ASC
LIMIT 100

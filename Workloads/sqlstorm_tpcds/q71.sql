WITH sales_union AS (
    SELECT
        ss_sold_date_sk AS sold_date_sk,
        ss_item_sk AS item_sk,
        ss_store_sk AS store_sk,
        CAST(NULL AS integer) AS call_center_sk,
        CAST(NULL AS integer) AS web_page_sk,
        ss_promo_sk AS promo_sk,
        ss_quantity AS qty,
        ss_net_profit AS net_profit,
        ss_net_paid AS net_paid
    FROM store_sales
    UNION ALL
    SELECT
        cs_sold_date_sk,
        cs_item_sk,
        CAST(NULL AS integer),
        cs_call_center_sk,
        CAST(NULL AS integer),
        cs_promo_sk,
        cs_quantity,
        cs_net_profit,
        cs_net_paid
    FROM catalog_sales
    UNION ALL
    SELECT
        ws_sold_date_sk,
        ws_item_sk,
        CAST(NULL AS integer),
        CAST(NULL AS integer),
        ws_web_page_sk,
        ws_promo_sk,
        ws_quantity,
        ws_net_profit,
        ws_net_paid
    FROM web_sales
),
returns_union AS (
    SELECT
        sr_returned_date_sk AS returned_date_sk,
        sr_item_sk AS item_sk,
        sr_store_sk AS store_sk,
        CAST(NULL AS integer) AS call_center_sk,
        CAST(NULL AS integer) AS web_page_sk,
        sr_return_quantity AS qty,
        sr_net_loss AS net_loss
    FROM store_returns
    UNION ALL
    SELECT
        cr_returned_date_sk,
        cr_item_sk,
        CAST(NULL AS integer),
        cr_call_center_sk,
        CAST(NULL AS integer),
        cr_return_quantity,
        cr_net_loss
    FROM catalog_returns
    UNION ALL
    SELECT
        wr_returned_date_sk,
        wr_item_sk,
        CAST(NULL AS integer),
        CAST(NULL AS integer),
        wr_web_page_sk,
        wr_return_quantity,
        wr_net_loss
    FROM web_returns
),
sales_agg AS (
    SELECT
        d.d_year AS year,
        d.d_moy AS month,
        i.i_category,
        i.i_class,
        CASE
            WHEN su.store_sk IS NOT NULL THEN 'store'
            WHEN su.call_center_sk IS NOT NULL THEN 'catalog'
            WHEN su.web_page_sk IS NOT NULL THEN 'web'
        END AS channel,
        COALESCE(su.store_sk, su.call_center_sk, su.web_page_sk) AS channel_key,
        p.p_promo_id,
        SUM(su.qty) AS total_qty,
        SUM(su.net_profit) AS total_net_profit,
        SUM(su.net_paid) AS total_net_paid
    FROM sales_union su
    JOIN date_dim d ON su.sold_date_sk = d.d_date_sk
    JOIN item i ON su.item_sk = i.i_item_sk
    LEFT JOIN promotion p ON su.promo_sk = p.p_promo_sk
    WHERE d.d_year BETWEEN 2000 AND 2002
    GROUP BY
        d.d_year,
        d.d_moy,
        i.i_category,
        i.i_class,
        CASE
            WHEN su.store_sk IS NOT NULL THEN 'store'
            WHEN su.call_center_sk IS NOT NULL THEN 'catalog'
            WHEN su.web_page_sk IS NOT NULL THEN 'web'
        END,
        COALESCE(su.store_sk, su.call_center_sk, su.web_page_sk),
        p.p_promo_id
),
returns_agg AS (
    SELECT
        d.d_year AS year,
        d.d_moy AS month,
        i.i_category,
        i.i_class,
        CASE
            WHEN ru.store_sk IS NOT NULL THEN 'store'
            WHEN ru.call_center_sk IS NOT NULL THEN 'catalog'
            WHEN ru.web_page_sk IS NOT NULL THEN 'web'
        END AS channel,
        COALESCE(ru.store_sk, ru.call_center_sk, ru.web_page_sk) AS channel_key,
        SUM(ru.qty) AS total_return_qty,
        SUM(ru.net_loss) AS total_return_loss
    FROM returns_union ru
    JOIN date_dim d ON ru.returned_date_sk = d.d_date_sk
    JOIN item i ON ru.item_sk = i.i_item_sk
    WHERE d.d_year BETWEEN 2000 AND 2002
    GROUP BY
        d.d_year,
        d.d_moy,
        i.i_category,
        i.i_class,
        CASE
            WHEN ru.store_sk IS NOT NULL THEN 'store'
            WHEN ru.call_center_sk IS NOT NULL THEN 'catalog'
            WHEN ru.web_page_sk IS NOT NULL THEN 'web'
        END,
        COALESCE(ru.store_sk, ru.call_center_sk, ru.web_page_sk)
),
combined AS (
    SELECT
        s.year,
        s.month,
        s.i_category,
        s.i_class,
        s.channel,
        s.p_promo_id,
        s.total_qty,
        s.total_net_profit,
        s.total_net_paid,
        COALESCE(r.total_return_qty, 0) AS total_return_qty,
        COALESCE(r.total_return_loss, 0) AS total_return_loss,
        s.total_net_profit - COALESCE(r.total_return_loss, 0) AS adj_net_profit,
        CASE WHEN s.total_qty > 0 THEN (s.total_net_profit - COALESCE(r.total_return_loss, 0)) / s.total_qty ELSE NULL END AS profit_per_unit,
        s.channel_key
    FROM sales_agg s
    LEFT JOIN returns_agg r
        ON s.year = r.year
        AND s.month = r.month
        AND s.i_category = r.i_category
        AND s.i_class = r.i_class
        AND s.channel = r.channel
        AND s.channel_key = r.channel_key
)
SELECT
    year,
    month,
    i_category,
    i_class,
    channel,
    p_promo_id,
    total_qty,
    total_return_qty,
    total_net_paid,
    adj_net_profit,
    profit_per_unit,
    ROW_NUMBER() OVER (PARTITION BY year, month, channel ORDER BY adj_net_profit DESC) AS profit_rank
FROM combined
WHERE profit_per_unit IS NOT NULL AND profit_per_unit > 0
ORDER BY year, month, channel, profit_rank
LIMIT 100

WITH
    store_data AS (
        SELECT
            ss.ss_sold_date_sk AS date_sk,
            ss.ss_item_sk AS item_sk,
            ss.ss_quantity,
            d.d_year
        FROM store_sales ss
        JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
        WHERE d.d_year = 2001
    ),
    catalog_data AS (
        SELECT
            cs.cs_sold_date_sk AS date_sk,
            cs.cs_item_sk AS item_sk,
            cs.cs_quantity,
            d.d_year
        FROM catalog_sales cs
        JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
        WHERE d.d_year = 2001
    ),
    web_data AS (
        SELECT
            ws.ws_sold_date_sk AS date_sk,
            ws.ws_item_sk AS item_sk,
            ws.ws_quantity,
            d.d_year
        FROM web_sales ws
        JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
        WHERE d.d_year = 2001
    ),
    intersect_keys AS (
        SELECT date_sk, item_sk
        FROM catalog_data
        INTERSECT
        SELECT date_sk, item_sk
        FROM store_data
    ),
    intersect_except AS (
        SELECT date_sk, item_sk
        FROM intersect_keys
        EXCEPT
        SELECT date_sk, item_sk
        FROM web_data
    ),
    full_outer_joined AS (
        SELECT
            COALESCE(sd.date_sk, cd.date_sk) AS date_sk,
            COALESCE(sd.item_sk, cd.item_sk) AS item_sk
        FROM store_data sd
        FULL OUTER JOIN catalog_data cd ON sd.date_sk = cd.date_sk
        WHERE sd.item_sk IS NOT NULL OR cd.item_sk IS NOT NULL
    ),
    combined AS (
        SELECT date_sk, item_sk, 'intersect_except' AS source
        FROM intersect_except
        UNION ALL
        SELECT date_sk, item_sk, 'full_outer' AS source
        FROM full_outer_joined
    )
SELECT
    ROW_NUMBER() OVER (ORDER BY date_sk) AS row_num,
    date_sk,
    item_sk,
    source
FROM combined
ORDER BY row_num

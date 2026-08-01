WITH
    ss AS (
        SELECT
            ss.ss_item_sk,
            i.i_item_id,
            ss.ss_net_profit,
            ss.ss_ext_sales_price,
            d.d_year
        FROM store_sales ss
        JOIN item i ON ss.ss_item_sk = i.i_item_sk
        JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    ),
    ws AS (
        SELECT
            ws.ws_item_sk,
            i.i_item_id,
            ws.ws_net_profit,
            ws.ws_ext_sales_price,
            d.d_year
        FROM web_sales ws
        JOIN item i ON ws.ws_item_sk = i.i_item_sk
        JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    ),
    full_join AS (
        SELECT
            COALESCE(ss.ss_item_sk, ws.ws_item_sk) AS item_sk,
            COALESCE(ss.i_item_id, ws.i_item_id) AS item_id,
            ss.ss_net_profit,
            ws.ws_net_profit,
            ss.ss_ext_sales_price,
            ws.ws_ext_sales_price,
            ss.d_year AS ss_year,
            ws.d_year AS ws_year
        FROM ss
        FULL OUTER JOIN ws ON ss.ss_item_sk = ws.ws_item_sk
    ),
    a AS (
        SELECT item_sk, item_id
        FROM full_join
        WHERE ss_net_profit > 1000
    ),
    b AS (
        SELECT item_sk, item_id
        FROM full_join
        WHERE ws_net_profit > 1000
    ),
    intersect_items AS (
        SELECT item_sk, item_id FROM a
        INTERSECT
        SELECT item_sk, item_id FROM b
    ),
    c AS (
        SELECT DISTINCT i.i_item_sk AS item_sk, i.i_item_id AS item_id
        FROM catalog_returns cr
        JOIN item i ON cr.cr_item_sk = i.i_item_sk
        WHERE cr.cr_return_amount > 200
    ),
    final_set AS (
        SELECT item_sk, item_id FROM intersect_items
        UNION
        SELECT item_sk, item_id FROM c
    )
SELECT
    f.item_id,
    (
        SELECT COALESCE(SUM(cr.cr_return_amount), 0)
        FROM catalog_returns cr
        WHERE cr.cr_item_sk = f.item_sk
    ) AS total_return_amount,
    ROW_NUMBER() OVER (
        ORDER BY (
            SELECT COALESCE(SUM(cr.cr_return_amount), 0)
            FROM catalog_returns cr
            WHERE cr.cr_item_sk = f.item_sk
        ) DESC
    ) AS rn
FROM final_set f
ORDER BY total_return_amount DESC
LIMIT 100

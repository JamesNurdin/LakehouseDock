WITH
    store_agg AS (
        SELECT
            i.i_item_sk,
            i.i_product_name,
            d.d_year,
            SUM(ss.ss_net_paid) AS store_net_paid,
            SUM(ss.ss_net_profit) AS store_net_profit,
            COUNT(*) AS store_transactions,
            CASE WHEN regexp_like(i.i_product_name, '(?i)deluxe') THEN 'Deluxe' ELSE 'Other' END AS product_category_flag
        FROM store_sales ss
        JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
        JOIN item i ON ss.ss_item_sk = i.i_item_sk
        WHERE d.d_year = 2001
          AND i.i_product_name LIKE '%Coffee%'
        GROUP BY i.i_item_sk, i.i_product_name, d.d_year,
                 CASE WHEN regexp_like(i.i_product_name, '(?i)deluxe') THEN 'Deluxe' ELSE 'Other' END
    ),
    web_agg AS (
        SELECT
            i.i_item_sk,
            i.i_product_name,
            d.d_year,
            SUM(ws.ws_net_paid) AS web_net_paid,
            SUM(ws.ws_net_profit) AS web_net_profit,
            COUNT(*) AS web_transactions,
            CASE WHEN regexp_like(i.i_product_name, '(?i)deluxe') THEN 'Deluxe' ELSE 'Other' END AS product_category_flag
        FROM web_sales ws
        JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
        JOIN item i ON ws.ws_item_sk = i.i_item_sk
        WHERE d.d_year = 2001
          AND i.i_product_name LIKE '%Coffee%'
        GROUP BY i.i_item_sk, i.i_product_name, d.d_year,
                 CASE WHEN regexp_like(i.i_product_name, '(?i)deluxe') THEN 'Deluxe' ELSE 'Other' END
    ),
    union_agg AS (
        SELECT i_item_sk, product_category_flag, d_year,
               store_net_paid AS net_paid,
               store_net_profit AS net_profit,
               store_transactions AS transactions
        FROM store_agg
        UNION DISTINCT
        SELECT i_item_sk, product_category_flag, d_year,
               web_net_paid,
               web_net_profit,
               web_transactions
        FROM web_agg
    ),
    intersect_items AS (
        SELECT i_item_sk FROM store_agg
        INTERSECT
        SELECT i_item_sk FROM web_agg
    ),
    full_joined AS (
        SELECT
            COALESCE(s.i_item_sk, w.i_item_sk) AS i_item_sk,
            COALESCE(s.d_year, w.d_year) AS d_year,
            s.store_net_paid,
            s.store_net_profit,
            s.store_transactions,
            w.web_net_paid,
            w.web_net_profit,
            w.web_transactions,
            COALESCE(s.product_category_flag, w.product_category_flag) AS product_category_flag
        FROM store_agg s
        FULL OUTER JOIN web_agg w
            ON s.i_item_sk = w.i_item_sk AND s.d_year = w.d_year
    ),
    final AS (
        SELECT
            fj.i_item_sk,
            i.i_product_name,
            fj.d_year,
            fj.product_category_flag,
            COALESCE(fj.store_net_paid, 0) + COALESCE(fj.web_net_paid, 0) AS total_net_paid,
            COALESCE(fj.store_net_profit, 0) + COALESCE(fj.web_net_profit, 0) AS total_net_profit,
            COALESCE(fj.store_transactions, 0) + COALESCE(fj.web_transactions, 0) AS total_transactions,
            CASE WHEN (COALESCE(fj.store_net_profit, 0) + COALESCE(fj.web_net_profit, 0)) > 0 THEN 'Positive' ELSE 'Non-Positive' END AS profit_sign,
            (SELECT COUNT(*) FROM store_returns sr WHERE sr.sr_item_sk = fj.i_item_sk) AS store_return_count
        FROM full_joined fj
        JOIN item i ON fj.i_item_sk = i.i_item_sk
        WHERE fj.product_category_flag = 'Deluxe'
          AND fj.i_item_sk IN (SELECT i_item_sk FROM intersect_items)
    )
SELECT *
FROM final
ORDER BY total_net_paid DESC
LIMIT 100

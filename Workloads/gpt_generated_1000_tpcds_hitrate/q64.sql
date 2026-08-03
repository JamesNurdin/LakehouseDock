WITH sales AS (
    SELECT
        s.s_store_id,
        s.s_store_name,
        i.i_item_id,
        i.i_item_desc,
        ss.ss_ext_sales_price AS amount,
        latest_promo.promo_name AS latest_promo_name
    FROM store_sales ss
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    -- join to promotion through the sales promo key (allowed)
    JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
    CROSS JOIN LATERAL (
        SELECT p2.p_promo_name AS promo_name
        FROM promotion p2
        WHERE p2.p_item_sk = i.i_item_sk
        ORDER BY p2.p_start_date_sk DESC
        LIMIT 1
    ) AS latest_promo
    WHERE i.i_category_id = 5
),
returns AS (
    SELECT
        CAST(NULL AS varchar) AS s_store_id,
        CAST(NULL AS varchar) AS s_store_name,
        i.i_item_id,
        i.i_item_desc,
        wr.wr_return_amt_inc_tax AS amount,
        CAST(NULL AS varchar) AS latest_promo_name
    FROM web_returns wr
    JOIN item i ON wr.wr_item_sk = i.i_item_sk
    WHERE i.i_category_id = 5
      AND wr.wr_return_amt_inc_tax > 0
),
combined AS (
    SELECT s_store_id, s_store_name, i_item_id, i_item_desc, amount, latest_promo_name FROM sales
    UNION
    SELECT s_store_id, s_store_name, i_item_id, i_item_desc, amount, latest_promo_name FROM returns
)
SELECT
    row_number() OVER (ORDER BY amount DESC) AS row_num,
    s_store_id,
    s_store_name,
    i_item_id,
    i_item_desc,
    amount,
    latest_promo_name
FROM combined
ORDER BY row_num
LIMIT 100

WITH base_sales AS (
    SELECT
        COALESCE(ss.ss_sold_date_sk, ws.ws_sold_date_sk) AS date_sk,
        COALESCE(ss.ss_item_sk, ws.ws_item_sk) AS item_sk,
        SUM(COALESCE(ss.ss_quantity, 0) + COALESCE(ws.ws_quantity, 0)) AS total_quantity,
        SUM(COALESCE(ss.ss_net_paid, 0) + COALESCE(ws.ws_net_paid, 0)) AS total_net_paid,
        SUM(COALESCE(ss.ss_net_profit, 0) + COALESCE(ws.ws_net_profit, 0)) AS total_net_profit
    FROM store_sales ss
    FULL OUTER JOIN web_sales ws
        ON ss.ss_sold_date_sk = ws.ws_sold_date_sk
        AND ss.ss_item_sk = ws.ws_item_sk
    GROUP BY COALESCE(ss.ss_sold_date_sk, ws.ws_sold_date_sk),
             COALESCE(ss.ss_item_sk, ws.ws_item_sk)
),

date_dim_filtered AS (
    SELECT *
    FROM date_dim
    WHERE d_date BETWEEN DATE '2001-01-01' AND DATE '2001-12-31'
      AND (d_holiday = 'Y' OR d_weekend = 'Y')
),

promo_items AS (
    SELECT DISTINCT p.p_item_sk AS item_sk
    FROM promotion p
    WHERE p.p_discount_active = 'Y'
),

item_info AS (
    SELECT i.i_item_sk,
           i.i_product_name,
           i.i_category,
           i.i_brand
    FROM item i
),

joined_sales AS (
    SELECT
        d.d_date,
        d.d_year,
        d.d_month_seq,
        i.i_item_sk,
        i.i_product_name,
        i.i_category,
        i.i_brand,
        bs.total_quantity,
        bs.total_net_paid,
        bs.total_net_profit,
        CASE WHEN pi.item_sk IS NOT NULL THEN 'YES' ELSE 'NO' END AS in_promo,
        bs.date_sk
    FROM base_sales bs
    LEFT JOIN date_dim_filtered d ON bs.date_sk = d.d_date_sk
    LEFT JOIN item_info i ON bs.item_sk = i.i_item_sk
    LEFT JOIN promo_items pi ON bs.item_sk = pi.item_sk
),

ranked_sales AS (
    SELECT
        js.*,
        RANK() OVER (PARTITION BY js.d_year ORDER BY js.total_quantity DESC) AS qty_rank_year,
        ROW_NUMBER() OVER (PARTITION BY js.d_year ORDER BY js.total_net_profit DESC) AS profit_row_year,
        SUM(js.total_net_paid) OVER (PARTITION BY js.d_year) AS year_total_net_paid,
        AVG(js.total_quantity) OVER (PARTITION BY js.d_month_seq) AS month_avg_quantity,
        (SELECT MAX(bs2.total_net_profit)
         FROM base_sales bs2
         WHERE bs2.date_sk = js.date_sk
           AND bs2.item_sk <> js.i_item_sk) AS max_other_profit,
        CONCAT('D', CAST(js.date_sk AS VARCHAR), '-I', CAST(js.i_item_sk AS VARCHAR)) AS composite_key
    FROM joined_sales js
    WHERE js.total_quantity > 0
),

final_sales AS (
    SELECT *
    FROM ranked_sales rs
    WHERE NOT EXISTS (
        SELECT 1
        FROM store_returns sr
        WHERE sr.sr_returned_date_sk = rs.date_sk
          AND sr.sr_item_sk = rs.i_item_sk
    )
      AND NOT EXISTS (
        SELECT 1
        FROM web_returns wr
        WHERE wr.wr_returned_date_sk = rs.date_sk
          AND wr.wr_item_sk = rs.i_item_sk
    )
)

SELECT
    fs.d_date AS sale_date,
    fs.d_year,
    fs.i_category,
    fs.i_brand,
    fs.total_quantity,
    fs.total_net_paid,
    fs.total_net_profit,
    fs.in_promo,
    fs.qty_rank_year,
    fs.profit_row_year,
    fs.year_total_net_paid,
    COALESCE(fs.month_avg_quantity, 0) AS month_avg_quantity,
    COALESCE(fs.max_other_profit, 0) AS max_other_profit,
    fs.composite_key,
    CASE WHEN fs.total_quantity IS NULL THEN 'ZERO' ELSE CAST(fs.total_quantity AS VARCHAR) END AS qty_str,
    (fs.total_net_paid - fs.total_net_profit) AS net_fee_estimate,
    NULLIF(fs.in_promo, 'NO') AS promo_flag_not_null,
    ROUND(fs.total_net_paid / NULLIF(fs.total_quantity, 0), 2) AS avg_price_per_qty
FROM final_sales fs

UNION ALL

SELECT
    d.d_date AS sale_date,
    d.d_year,
    NULL AS i_category,
    NULL AS i_brand,
    CAST(0 AS BIGINT) AS total_quantity,
    CAST(0.0 AS DECIMAL(15,2)) AS total_net_paid,
    CAST(0.0 AS DECIMAL(15,2)) AS total_net_profit,
    'NO' AS in_promo,
    CAST(NULL AS BIGINT) AS qty_rank_year,
    CAST(NULL AS BIGINT) AS profit_row_year,
    CAST(0.0 AS DECIMAL(15,2)) AS year_total_net_paid,
    CAST(0.0 AS DOUBLE) AS month_avg_quantity,
    CAST(NULL AS DECIMAL(15,2)) AS max_other_profit,
    CONCAT('D', CAST(d.d_date_sk AS VARCHAR), '-I', CAST(NULL AS VARCHAR)) AS composite_key,
    'ZERO' AS qty_str,
    CAST(0.0 AS DECIMAL(15,2)) AS net_fee_estimate,
    CAST(NULL AS VARCHAR) AS promo_flag_not_null,
    CAST(NULL AS DOUBLE) AS avg_price_per_qty
FROM date_dim_filtered d
WHERE NOT EXISTS (
    SELECT 1
    FROM final_sales fs
    WHERE fs.d_date = d.d_date
)
ORDER BY sale_date, total_quantity DESC

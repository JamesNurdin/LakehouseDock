WITH
sales_union AS (
    SELECT
        cs_order_number AS order_number,
        cs_sold_date_sk AS sold_date_sk,
        cs_item_sk AS item_sk,
        cs_quantity AS quantity,
        cs_ext_sales_price AS ext_sales_price,
        cs_ext_discount_amt AS ext_discount_amt,
        cs_net_profit AS net_profit,
        'catalog' AS channel
    FROM catalog_sales
    UNION ALL
    SELECT
        ss_ticket_number AS order_number,
        ss_sold_date_sk AS sold_date_sk,
        ss_item_sk AS item_sk,
        ss_quantity AS quantity,
        ss_ext_sales_price AS ext_sales_price,
        ss_ext_discount_amt AS ext_discount_amt,
        ss_net_profit AS net_profit,
        'store' AS channel
    FROM store_sales
    UNION ALL
    SELECT
        ws_order_number AS order_number,
        ws_sold_date_sk AS sold_date_sk,
        ws_item_sk AS item_sk,
        ws_quantity AS quantity,
        ws_ext_sales_price AS ext_sales_price,
        ws_ext_discount_amt AS ext_discount_amt,
        ws_net_profit AS net_profit,
        'web' AS channel
    FROM web_sales
),
promo_sales AS (
    SELECT
        COALESCE(su.order_number, -1) AS order_number,
        su.sold_date_sk,
        COALESCE(su.item_sk, p.p_item_sk) AS item_sk,
        CASE WHEN su.channel IS NULL THEN 'promotion_only' ELSE su.channel END AS channel,
        p.p_promo_sk,
        p.p_discount_active,
        su.ext_sales_price,
        su.ext_discount_amt,
        su.net_profit
    FROM sales_union su
    FULL OUTER JOIN promotion p ON su.item_sk = p.p_item_sk
),
max_profit_per_month AS (
    SELECT
        d.d_year,
        d.d_month_seq,
        ps.channel,
        MAX(ps.net_profit) AS max_monthly_profit
    FROM promo_sales ps
    LEFT JOIN date_dim d ON ps.sold_date_sk = d.d_date_sk
    WHERE d.d_year IS NOT NULL
    GROUP BY d.d_year, d.d_month_seq, ps.channel
),
ranked_sales AS (
    SELECT
        ps.order_number,
        d.d_year,
        d.d_month_seq,
        ps.channel,
        ps.ext_sales_price,
        ps.ext_discount_amt,
        ps.net_profit,
        i.i_item_id,
        i.i_product_name,
        ROW_NUMBER() OVER (PARTITION BY d.d_year, d.d_month_seq, ps.channel ORDER BY ps.net_profit DESC) AS profit_rank,
        COALESCE(
            (SELECT avg(cs_ext_sales_price) FROM catalog_sales cs2 WHERE cs2.cs_item_sk = ps.item_sk),
            0
        ) AS avg_catalog_sales_price,
        CASE WHEN ps.ext_discount_amt IS NULL THEN 0 ELSE ps.ext_discount_amt END AS discount_amount,
        CASE WHEN ps.ext_sales_price < 0 THEN NULL ELSE ps.ext_sales_price END AS adjusted_sales_price,
        CONCAT('Order#', CAST(ps.order_number AS VARCHAR)) AS order_label,
        (SELECT COUNT(*) FROM store_sales ss2 WHERE ss2.ss_item_sk = ps.item_sk AND ss2.ss_sold_date_sk = ps.sold_date_sk) AS same_item_store_sales_count,
        CASE
            WHEN ((ps.ext_discount_amt > 0 AND ps.ext_sales_price > 0) OR (ps.ext_discount_amt IS NULL AND ps.ext_sales_price IS NOT NULL)) AND ps.net_profit > 0 THEN 1
            ELSE 0
        END AS qualifies
    FROM promo_sales ps
    LEFT JOIN date_dim d ON ps.sold_date_sk = d.d_date_sk
    LEFT JOIN item i ON ps.item_sk = i.i_item_sk
    WHERE d.d_year IS NOT NULL
)

SELECT
    rs.d_year,
    rs.d_month_seq,
    rs.channel,
    GROUPING(rs.channel) AS channel_grouping,
    GROUPING(rs.d_month_seq) AS month_grouping,
    GROUPING(rs.d_year) AS year_grouping,
    COUNT(*) AS total_sales,
    SUM(rs.ext_sales_price) AS total_ext_sales,
    SUM(rs.net_profit) AS total_net_profit,
    AVG(rs.discount_amount) AS avg_discount,
    MAX(rs.adjusted_sales_price) AS max_adjusted_sales,
    MAX(rs.profit_rank) AS max_profit_rank,
    MAX(rs.avg_catalog_sales_price) AS max_avg_catalog_price,
    MAX(CASE WHEN rs.qualifies = 1 THEN rs.ext_sales_price END) AS max_qualifying_ext_sales,
    COUNT(DISTINCT rs.order_label) AS distinct_order_labels,
    MAX(COALESCE(mp.max_monthly_profit, 0)) AS max_monthly_profit_across_channels,
    (SELECT COUNT(*) FROM (
        SELECT DISTINCT order_number FROM sales_union
        EXCEPT
        SELECT DISTINCT ss_ticket_number FROM store_sales
    ) diff) AS orders_not_in_store_sales
FROM ranked_sales rs
LEFT JOIN max_profit_per_month mp ON rs.d_year = mp.d_year AND rs.d_month_seq = mp.d_month_seq AND rs.channel = mp.channel
GROUP BY GROUPING SETS ((rs.d_year, rs.d_month_seq, rs.channel), (rs.d_year, rs.d_month_seq), (rs.d_year), ())
HAVING COUNT(*) > 0
ORDER BY rs.d_year, rs.d_month_seq, rs.channel
LIMIT 100

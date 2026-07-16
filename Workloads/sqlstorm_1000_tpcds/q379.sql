WITH date_range AS (
    SELECT d_date_sk, d_month_seq, d_date
    FROM date_dim
    WHERE d_date BETWEEN DATE '2020-01-01' AND DATE '2020-12-31'
),
store_agg AS (
    SELECT
        d_month_seq,
        i_category,
        i_category_id,
        total_store_profit,
        total_store_quantity,
        rank() OVER (PARTITION BY d_month_seq ORDER BY total_store_profit DESC) AS profit_rank_store
    FROM (
        SELECT
            dr.d_month_seq,
            i.i_category,
            i.i_category_id,
            sum(ss.ss_net_profit) AS total_store_profit,
            sum(ss.ss_quantity) AS total_store_quantity
        FROM store_sales ss
        JOIN date_range dr ON ss.ss_sold_date_sk = dr.d_date_sk
        JOIN item i ON ss.ss_item_sk = i.i_item_sk
        GROUP BY dr.d_month_seq, i.i_category, i.i_category_id
    ) s
),
catalog_agg AS (
    SELECT
        d_month_seq,
        i_category,
        i_category_id,
        total_catalog_profit,
        total_catalog_quantity,
        rank() OVER (PARTITION BY d_month_seq ORDER BY total_catalog_profit DESC) AS profit_rank_catalog
    FROM (
        SELECT
            dr.d_month_seq,
            i.i_category,
            i.i_category_id,
            sum(cs.cs_net_profit) AS total_catalog_profit,
            sum(cs.cs_quantity) AS total_catalog_quantity
        FROM catalog_sales cs
        JOIN date_range dr ON cs.cs_sold_date_sk = dr.d_date_sk
        JOIN item i ON cs.cs_item_sk = i.i_item_sk
        GROUP BY dr.d_month_seq, i.i_category, i.i_category_id
    ) c
),
web_agg AS (
    SELECT
        d_month_seq,
        i_category,
        i_category_id,
        total_web_profit,
        total_web_quantity,
        rank() OVER (PARTITION BY d_month_seq ORDER BY total_web_profit DESC) AS profit_rank_web
    FROM (
        SELECT
            dr.d_month_seq,
            i.i_category,
            i.i_category_id,
            sum(ws.ws_net_profit) AS total_web_profit,
            sum(ws.ws_quantity) AS total_web_quantity
        FROM web_sales ws
        JOIN date_range dr ON ws.ws_sold_date_sk = dr.d_date_sk
        JOIN item i ON ws.ws_item_sk = i.i_item_sk
        GROUP BY dr.d_month_seq, i.i_category, i.i_category_id
    ) w
),
combined_profit AS (
    SELECT
        COALESCE(sc.d_month_seq, w.d_month_seq) AS d_month_seq,
        COALESCE(sc.i_category, w.i_category) AS i_category,
        COALESCE(sc.i_category_id, w.i_category_id) AS i_category_id,
        sc.total_store_profit,
        sc.total_catalog_profit,
        w.total_web_profit,
        COALESCE(sc.total_store_profit, 0) + COALESCE(sc.total_catalog_profit, 0) + COALESCE(w.total_web_profit, 0) AS total_combined_profit,
        sc.profit_rank_store,
        sc.profit_rank_catalog,
        w.profit_rank_web
    FROM (
        SELECT
            COALESCE(s.d_month_seq, c.d_month_seq) AS d_month_seq,
            COALESCE(s.i_category, c.i_category) AS i_category,
            COALESCE(s.i_category_id, c.i_category_id) AS i_category_id,
            s.total_store_profit,
            c.total_catalog_profit,
            s.profit_rank_store,
            c.profit_rank_catalog
        FROM store_agg s
        FULL OUTER JOIN catalog_agg c
            ON s.d_month_seq = c.d_month_seq AND s.i_category_id = c.i_category_id
    ) sc
    FULL OUTER JOIN web_agg w
        ON sc.d_month_seq = w.d_month_seq AND sc.i_category_id = w.i_category_id
),
store_returns_agg AS (
    SELECT
        dr.d_month_seq,
        'Returns' AS i_category,
        -1 AS i_category_id,
        CAST(NULL AS DECIMAL(38,2)) AS total_store_profit,
        CAST(NULL AS DECIMAL(38,2)) AS total_catalog_profit,
        CAST(NULL AS DECIMAL(38,2)) AS total_web_profit,
        -SUM(sr.sr_net_loss) AS total_combined_profit,
        CAST(NULL AS INTEGER) AS profit_rank_store,
        CAST(NULL AS INTEGER) AS profit_rank_catalog,
        CAST(NULL AS INTEGER) AS profit_rank_web
    FROM store_returns sr
    JOIN date_range dr ON sr.sr_returned_date_sk = dr.d_date_sk
    GROUP BY dr.d_month_seq
),
catalog_returns_agg AS (
    SELECT
        dr.d_month_seq,
        'Returns' AS i_category,
        -1 AS i_category_id,
        CAST(NULL AS DECIMAL(38,2)) AS total_store_profit,
        CAST(NULL AS DECIMAL(38,2)) AS total_catalog_profit,
        CAST(NULL AS DECIMAL(38,2)) AS total_web_profit,
        -SUM(cr.cr_net_loss) AS total_combined_profit,
        CAST(NULL AS INTEGER) AS profit_rank_store,
        CAST(NULL AS INTEGER) AS profit_rank_catalog,
        CAST(NULL AS INTEGER) AS profit_rank_web
    FROM catalog_returns cr
    JOIN date_range dr ON cr.cr_returned_date_sk = dr.d_date_sk
    GROUP BY dr.d_month_seq
),
web_returns_agg AS (
    SELECT
        dr.d_month_seq,
        'Returns' AS i_category,
        -1 AS i_category_id,
        CAST(NULL AS DECIMAL(38,2)) AS total_store_profit,
        CAST(NULL AS DECIMAL(38,2)) AS total_catalog_profit,
        CAST(NULL AS DECIMAL(38,2)) AS total_web_profit,
        -SUM(wr.wr_net_loss) AS total_combined_profit,
        CAST(NULL AS INTEGER) AS profit_rank_store,
        CAST(NULL AS INTEGER) AS profit_rank_catalog,
        CAST(NULL AS INTEGER) AS profit_rank_web
    FROM web_returns wr
    JOIN date_range dr ON wr.wr_returned_date_sk = dr.d_date_sk
    GROUP BY dr.d_month_seq
),
combined_loss AS (
    SELECT * FROM store_returns_agg
    UNION ALL
    SELECT * FROM catalog_returns_agg
    UNION ALL
    SELECT * FROM web_returns_agg
),
final_combined AS (
    SELECT
        d_month_seq,
        i_category,
        i_category_id,
        total_store_profit,
        total_catalog_profit,
        total_web_profit,
        total_combined_profit,
        profit_rank_store,
        profit_rank_catalog,
        profit_rank_web
    FROM combined_profit
    UNION ALL
    SELECT
        d_month_seq,
        i_category,
        i_category_id,
        total_store_profit,
        total_catalog_profit,
        total_web_profit,
        total_combined_profit,
        profit_rank_store,
        profit_rank_catalog,
        profit_rank_web
    FROM combined_loss
)
SELECT
    fc.d_month_seq,
    fc.i_category,
    fc.total_combined_profit,
    fc.profit_rank_store,
    fc.profit_rank_catalog,
    fc.profit_rank_web,
    CASE 
        WHEN fc.profit_rank_store = 1 THEN 'Top Store'
        WHEN fc.profit_rank_catalog = 1 THEN 'Top Catalog'
        WHEN fc.profit_rank_web = 1 THEN 'Top Web'
        WHEN fc.i_category = 'Returns' THEN 'Return Loss'
        ELSE 'Other'
    END AS top_channel_flag,
    (SELECT AVG(fc2.total_combined_profit) FROM final_combined fc2 WHERE fc2.i_category = fc.i_category) AS avg_category_profit,
    (SELECT MAX(fc3.total_combined_profit) FROM final_combined fc3 WHERE fc3.d_month_seq = fc.d_month_seq) AS max_month_profit,
    CASE 
        WHEN fc.total_combined_profit > 1000000 THEN 'High'
        WHEN fc.total_combined_profit > 0 THEN 'Medium'
        ELSE 'Low'
    END AS profit_bucket,
    COALESCE(fc.i_category, 'UNKNOWN') || ' - ' || CAST(fc.d_month_seq AS VARCHAR) AS category_month_label
FROM final_combined fc
WHERE (fc.total_combined_profit > 0 AND fc.d_month_seq % 2 = 0) OR fc.i_category = 'Returns'
ORDER BY fc.total_combined_profit DESC
LIMIT 200

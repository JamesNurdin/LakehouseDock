-- Goal: compare net loss from catalog and web returns per item and reason, enrich with sales data, and rank the combined loss.
WITH catalog_agg AS (
    SELECT
        i.i_item_sk,
        i.i_category,
        r.r_reason_desc,
        SUM(cr.cr_net_loss) AS total_net_loss,
        COUNT(*) AS return_cnt,
        CASE WHEN SUM(cr.cr_net_loss) > 1000 THEN 'High' ELSE 'Low' END AS loss_level
    FROM catalog_returns cr
    JOIN item i ON cr.cr_item_sk = i.i_item_sk
    JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
    JOIN household_demographics hd ON cr.cr_refunded_hdemo_sk = hd.hd_demo_sk
    WHERE cr.cr_returned_date_sk BETWEEN 2451910 AND 2451919
    GROUP BY i.i_item_sk, i.i_category, r.r_reason_desc
),
web_agg AS (
    SELECT
        i.i_item_sk,
        i.i_category,
        r.r_reason_desc,
        SUM(wr.wr_net_loss) AS total_net_loss,
        COUNT(*) AS return_cnt,
        CASE WHEN SUM(wr.wr_net_loss) > 1000 THEN 'High' ELSE 'Low' END AS loss_level
    FROM web_returns wr
    JOIN item i ON wr.wr_item_sk = i.i_item_sk
    JOIN reason r ON wr.wr_reason_sk = r.r_reason_sk
    JOIN household_demographics hd ON wr.wr_refunded_hdemo_sk = hd.hd_demo_sk
    WHERE wr.wr_returned_date_sk BETWEEN 2451910 AND 2451919
    GROUP BY i.i_item_sk, i.i_category, r.r_reason_desc
),
-- Set operation combining the two aggregated result sets
combined AS (
    SELECT * FROM catalog_agg
    UNION ALL
    SELECT * FROM web_agg
),
-- Full outer join keeps unmatched rows from both sides
full_joined AS (
    SELECT
        ca.i_item_sk,
        ca.i_category,
        ca.r_reason_desc,
        ca.total_net_loss AS catalog_net_loss,
        ca.return_cnt AS catalog_returns,
        ca.loss_level AS catalog_loss_level,
        wa.total_net_loss AS web_net_loss,
        wa.return_cnt AS web_returns,
        wa.loss_level AS web_loss_level
    FROM catalog_agg ca
    FULL OUTER JOIN web_agg wa
        ON ca.i_item_sk = wa.i_item_sk
       AND ca.r_reason_desc = wa.r_reason_desc
),
-- Keep rows where a correlated EXISTS finds at least one matching household with a given buy potential
filtered AS (
    SELECT
        fj.*, 
        ROW_NUMBER() OVER (ORDER BY COALESCE(fj.catalog_net_loss,0) + COALESCE(fj.web_net_loss,0) DESC) AS row_num,
        (SELECT COUNT(*) FROM reason r2 WHERE r2.r_reason_desc = fj.r_reason_desc) AS reason_occurrences
    FROM full_joined fj
    WHERE EXISTS (
        SELECT 1
        FROM catalog_returns cr
        JOIN household_demographics hd ON cr.cr_refunded_hdemo_sk = hd.hd_demo_sk
        WHERE cr.cr_item_sk = fj.i_item_sk
          AND hd.hd_buy_potential = '5001-10000'
    )
    OR EXISTS (
        SELECT 1
        FROM web_returns wr
        JOIN household_demographics hd ON wr.wr_refunded_hdemo_sk = hd.hd_demo_sk
        WHERE wr.wr_item_sk = fj.i_item_sk
          AND hd.hd_buy_potential = '5001-10000'
    )
)
SELECT
    f.i_item_sk,
    f.i_category,
    f.r_reason_desc,
    f.catalog_net_loss,
    f.web_net_loss,
    f.row_num,
    CASE
        WHEN COALESCE(f.catalog_net_loss,0) + COALESCE(f.web_net_loss,0) > 2000 THEN 'Very High'
        WHEN COALESCE(f.catalog_net_loss,0) + COALESCE(f.web_net_loss,0) > 1000 THEN 'High'
        ELSE 'Moderate'
    END AS overall_loss_category,
    l.lateral_sum
FROM filtered f
LEFT JOIN LATERAL (
    SELECT SUM(ws.ws_ext_sales_price) AS lateral_sum
    FROM web_sales ws
    WHERE ws.ws_item_sk = f.i_item_sk
      AND ws.ws_sold_date_sk BETWEEN 2451910 AND 2451919
) l ON true
ORDER BY f.row_num ASC
LIMIT 100

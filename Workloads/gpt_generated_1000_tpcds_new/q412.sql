WITH sales_agg AS (
    SELECT i.i_item_id,
           ws.ws_web_site_sk,
           SUM(ws.ws_net_profit) AS total_profit,
           SUM(ws.ws_quantity) AS total_qty,
           CASE WHEN SUM(ws.ws_net_profit) > 10000 THEN 'HIGH' ELSE 'LOW' END AS profit_category
    FROM web_sales ws
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    JOIN web_site s ON ws.ws_web_site_sk = s.web_site_sk
    WHERE s.web_class = 'Unknown'
    GROUP BY i.i_item_id, ws.ws_web_site_sk
),
returns_agg AS (
    SELECT i.i_item_id,
           wr.wr_web_page_sk,
           SUM(wr.wr_net_loss) AS total_loss,
           COUNT(*) AS return_cnt,
           CASE WHEN SUM(wr.wr_net_loss) > 5000 THEN 'HIGH' ELSE 'LOW' END AS loss_category
    FROM web_returns wr
    JOIN item i ON wr.wr_item_sk = i.i_item_sk
    JOIN web_page wp ON wr.wr_web_page_sk = wp.wp_web_page_sk
    GROUP BY i.i_item_id, wr.wr_web_page_sk
),
union_set AS (
    SELECT i_item_id FROM sales_agg
    UNION
    SELECT i_item_id FROM returns_agg
),
intersect_set AS (
    SELECT i_item_id FROM sales_agg WHERE total_profit > 5000
    INTERSECT
    SELECT i_item_id FROM returns_agg WHERE total_loss > 2000
)
SELECT us.i_item_id,
       sa.total_profit,
       ra.total_loss,
       CASE WHEN sa.total_profit IS NULL THEN 'NO_SALES' ELSE 'HAS_SALES' END AS sales_flag,
       CASE WHEN ra.total_loss IS NULL THEN 'NO_RETURNS' ELSE 'HAS_RETURNS' END AS return_flag,
       (SELECT COUNT(*)
        FROM promotion p
        WHERE p.p_item_sk = i.i_item_sk
          AND p.p_discount_active = 'Y') AS active_promo_cnt
FROM union_set us
LEFT JOIN sales_agg sa ON us.i_item_id = sa.i_item_id
LEFT JOIN returns_agg ra ON us.i_item_id = ra.i_item_id
JOIN item i ON i.i_item_id = us.i_item_id
WHERE us.i_item_id IN (SELECT i_item_id FROM intersect_set)
ORDER BY COALESCE(sa.total_profit, 0) DESC
LIMIT 100

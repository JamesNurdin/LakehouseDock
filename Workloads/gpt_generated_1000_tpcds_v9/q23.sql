WITH date_2001 AS (
    SELECT d_date_sk
    FROM date_dim
    WHERE d_year = 2001
),
catalog_agg AS (
    SELECT
        w.w_warehouse_sk,
        w.w_city,
        w.w_state,
        SUM(cr.cr_net_loss) AS cat_net_loss
    FROM catalog_returns cr
    JOIN date_2001 d ON cr.cr_returned_date_sk = d.d_date_sk
    JOIN warehouse w ON cr.cr_warehouse_sk = w.w_warehouse_sk
    GROUP BY w.w_warehouse_sk, w.w_city, w.w_state
),
web_agg AS (
    SELECT
        w.w_warehouse_sk,
        w.w_city,
        w.w_state,
        SUM(wr.wr_net_loss) AS web_net_loss
    FROM web_returns wr
    JOIN date_2001 d ON wr.wr_returned_date_sk = d.d_date_sk
    JOIN web_sales ws ON wr.wr_item_sk = ws.ws_item_sk
        AND wr.wr_order_number = ws.ws_order_number
    JOIN warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
    GROUP BY w.w_warehouse_sk, w.w_city, w.w_state
),
combined_agg AS (
    SELECT
        COALESCE(ca.w_warehouse_sk, wa.w_warehouse_sk) AS warehouse_sk,
        COALESCE(ca.w_city, wa.w_city) AS w_city,
        COALESCE(ca.w_state, wa.w_state) AS w_state,
        COALESCE(ca.cat_net_loss, 0) + COALESCE(wa.web_net_loss, 0) AS total_net_loss
    FROM catalog_agg ca
    FULL OUTER JOIN web_agg wa ON ca.w_warehouse_sk = wa.w_warehouse_sk
)
SELECT
    ca.warehouse_sk,
    ca.w_city,
    ca.w_state,
    ca.total_net_loss,
    regexp_extract(ca.w_city, '^([A-Za-z]+)', 1) AS city_prefix,
    ca.w_city || ', ' || ca.w_state AS city_state,
    CASE WHEN ca.total_net_loss > (
            SELECT AVG(total_net_loss) FROM combined_agg
        ) THEN true ELSE false END AS exceeds_average
FROM combined_agg ca
WHERE ca.w_city LIKE 'S%'
  AND regexp_like(ca.w_city, '^San|^Santa')
ORDER BY ca.total_net_loss DESC
LIMIT 100

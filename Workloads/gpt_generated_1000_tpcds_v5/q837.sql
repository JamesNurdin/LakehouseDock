WITH filtered AS (
    SELECT
        s.s_store_id AS s_store_id,
        s.s_store_name AS s_store_name,
        cp.cp_department AS cp_department,
        d_ret.d_year AS d_year,
        cr.cr_net_loss AS cr_net_loss,
        ws.ws_net_profit AS ws_net_profit
    FROM catalog_returns cr
    JOIN date_dim d_ret
      ON cr.cr_returned_date_sk = d_ret.d_date_sk
    JOIN catalog_page cp
      ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN reason r
      ON cr.cr_reason_sk = r.r_reason_sk
    JOIN web_sales ws
      ON ws.ws_sold_date_sk = d_ret.d_date_sk
    JOIN store s
      ON s.s_closed_date_sk = d_ret.d_date_sk
    WHERE d_ret.d_year = 2001
      AND cp.cp_department = 'Books'
      AND cr.cr_return_quantity > 1
      AND ws.ws_quantity >= 2
      AND s.s_market_manager = 'Richard Bell'
),
agg AS (
    SELECT
        s_store_id,
        s_store_name,
        cp_department,
        d_year,
        SUM(cr_net_loss) AS total_net_loss,
        SUM(ws_net_profit) AS total_net_profit,
        CASE WHEN SUM(cr_net_loss) > 10000 THEN 'HIGH' ELSE 'LOW' END AS loss_category
    FROM filtered
    GROUP BY s_store_id, s_store_name, cp_department, d_year
)
SELECT
    s_store_id,
    s_store_name,
    cp_department,
    d_year,
    total_net_loss,
    total_net_profit,
    loss_category,
    ROW_NUMBER() OVER (PARTITION BY s_store_id ORDER BY total_net_loss DESC) AS loss_rank
FROM agg
ORDER BY total_net_loss DESC
LIMIT 100

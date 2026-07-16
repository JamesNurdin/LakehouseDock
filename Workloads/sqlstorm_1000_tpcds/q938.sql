WITH sales_agg AS (
    SELECT d.d_year AS year,
           d.d_moy AS month,
           i.i_category,
           cc.cc_state AS state,
           'catalog' AS channel,
           sum(cs.cs_net_profit) AS total_profit,
           sum(cs.cs_quantity) AS total_quantity
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
    GROUP BY 1,2,3,4,5
    UNION ALL
    SELECT d.d_year,
           d.d_moy,
           i.i_category,
           w.w_state AS state,
           'web' AS channel,
           sum(ws.ws_net_profit) AS total_profit,
           sum(ws.ws_quantity) AS total_quantity
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    JOIN warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
    GROUP BY 1,2,3,4,5
    UNION ALL
    SELECT d.d_year,
           d.d_moy,
           i.i_category,
           s.s_state,
           'store' AS channel,
           sum(ss.ss_net_profit) AS total_profit,
           sum(ss.ss_quantity) AS total_quantity
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    GROUP BY 1,2,3,4,5
),
returns_agg AS (
    SELECT d.d_year AS year,
           d.d_moy AS month,
           i.i_category,
           cc.cc_state AS state,
           'catalog' AS channel,
           sum(cr.cr_net_loss) AS total_loss,
           sum(cr.cr_return_quantity) AS total_return_quantity
    FROM catalog_returns cr
    JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
    JOIN item i ON cr.cr_item_sk = i.i_item_sk
    JOIN call_center cc ON cr.cr_call_center_sk = cc.cc_call_center_sk
    GROUP BY 1,2,3,4,5
    UNION ALL
    SELECT d.d_year,
           d.d_moy,
           i.i_category,
           null AS state,
           'web' AS channel,
           sum(wr.wr_net_loss) AS total_loss,
           sum(wr.wr_return_quantity) AS total_return_quantity
    FROM web_returns wr
    JOIN date_dim d ON wr.wr_returned_date_sk = d.d_date_sk
    JOIN item i ON wr.wr_item_sk = i.i_item_sk
    GROUP BY 1,2,3,4,5
    UNION ALL
    SELECT d.d_year,
           d.d_moy,
           i.i_category,
           s.s_state,
           'store' AS channel,
           sum(sr.sr_net_loss) AS total_loss,
           sum(sr.sr_return_quantity) AS total_return_quantity
    FROM store_returns sr
    JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
    JOIN item i ON sr.sr_item_sk = i.i_item_sk
    JOIN store s ON sr.sr_store_sk = s.s_store_sk
    GROUP BY 1,2,3,4,5
),
joined AS (
    SELECT
        s.year,
        s.month,
        s.state,
        s.i_category,
        s.channel,
        s.total_profit,
        s.total_quantity,
        coalesce(r.total_loss, 0) AS total_loss,
        coalesce(r.total_return_quantity, 0) AS total_return_quantity,
        s.total_profit - coalesce(r.total_loss, 0) AS net_profit
    FROM sales_agg s
    LEFT JOIN returns_agg r
        ON s.year = r.year
       AND s.month = r.month
       AND s.i_category = r.i_category
       AND s.channel = r.channel
       AND (s.state = r.state OR (s.state IS NULL AND r.state IS NULL))
    WHERE s.total_profit > 0
),
final AS (
    SELECT
        year,
        month,
        state,
        i_category,
        channel,
        total_profit,
        total_quantity,
        total_loss,
        total_return_quantity,
        net_profit,
        net_profit / nullif(total_quantity, 0) AS profit_per_quantity,
        CASE WHEN (total_quantity + total_return_quantity) > 0
             THEN net_profit / (total_quantity + total_return_quantity)
             ELSE null END AS profit_per_total_units,
        row_number() OVER (PARTITION BY year, month ORDER BY net_profit DESC) AS profit_rank_month,
        sum(net_profit) OVER (PARTITION BY i_category, channel ORDER BY year, month ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS cumulative_profit,
        net_profit - lag(net_profit) OVER (PARTITION BY i_category, channel ORDER BY year, month) AS profit_change_from_prev_month
    FROM joined
)
SELECT *
FROM final
WHERE profit_rank_month <= 5
ORDER BY year, month, profit_rank_month

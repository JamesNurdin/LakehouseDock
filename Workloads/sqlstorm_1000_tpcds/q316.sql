WITH sales AS (
    SELECT
        d.d_year,
        d.d_month_seq,
        s.s_state AS region_state,
        'store' AS channel,
        i.i_item_id,
        i.i_product_name,
        SUM(ss.ss_net_paid) AS net_paid,
        SUM(ss.ss_net_profit) AS net_profit,
        SUM(ss.ss_quantity) AS quantity
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    GROUP BY d.d_year, d.d_month_seq, s.s_state, i.i_item_id, i.i_product_name
    UNION ALL
    SELECT
        d.d_year,
        d.d_month_seq,
        w.web_state AS region_state,
        'web' AS channel,
        i.i_item_id,
        i.i_product_name,
        SUM(ws.ws_net_paid) AS net_paid,
        SUM(ws.ws_net_profit) AS net_profit,
        SUM(ws.ws_quantity) AS quantity
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN web_site w ON ws.ws_web_site_sk = w.web_site_sk
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    GROUP BY d.d_year, d.d_month_seq, w.web_state, i.i_item_id, i.i_product_name
    UNION ALL
    SELECT
        d.d_year,
        d.d_month_seq,
        cc.cc_state AS region_state,
        'catalog' AS channel,
        i.i_item_id,
        i.i_product_name,
        SUM(cs.cs_net_paid) AS net_paid,
        SUM(cs.cs_net_profit) AS net_profit,
        SUM(cs.cs_quantity) AS quantity
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    GROUP BY d.d_year, d.d_month_seq, cc.cc_state, i.i_item_id, i.i_product_name
),
returns AS (
    SELECT
        d.d_year,
        d.d_month_seq,
        s.s_state AS region_state,
        'store' AS channel,
        i.i_item_id,
        i.i_product_name,
        SUM(sr.sr_net_loss) AS net_loss,
        SUM(sr.sr_return_quantity) AS return_qty
    FROM store_returns sr
    JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
    JOIN store s ON sr.sr_store_sk = s.s_store_sk
    JOIN item i ON sr.sr_item_sk = i.i_item_sk
    GROUP BY d.d_year, d.d_month_seq, s.s_state, i.i_item_id, i.i_product_name
    UNION ALL
    SELECT
        d.d_year,
        d.d_month_seq,
        w.web_state AS region_state,
        'web' AS channel,
        i.i_item_id,
        i.i_product_name,
        SUM(wr.wr_net_loss) AS net_loss,
        SUM(wr.wr_return_quantity) AS return_qty
    FROM web_returns wr
    JOIN web_sales ws ON wr.wr_order_number = ws.ws_order_number AND wr.wr_item_sk = ws.ws_item_sk
    JOIN date_dim d ON wr.wr_returned_date_sk = d.d_date_sk
    JOIN web_site w ON ws.ws_web_site_sk = w.web_site_sk
    JOIN item i ON wr.wr_item_sk = i.i_item_sk
    GROUP BY d.d_year, d.d_month_seq, w.web_state, i.i_item_id, i.i_product_name
    UNION ALL
    SELECT
        d.d_year,
        d.d_month_seq,
        cc.cc_state AS region_state,
        'catalog' AS channel,
        i.i_item_id,
        i.i_product_name,
        SUM(cr.cr_net_loss) AS net_loss,
        SUM(cr.cr_return_quantity) AS return_qty
    FROM catalog_returns cr
    JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
    JOIN call_center cc ON cr.cr_call_center_sk = cc.cc_call_center_sk
    JOIN item i ON cr.cr_item_sk = i.i_item_sk
    GROUP BY d.d_year, d.d_month_seq, cc.cc_state, i.i_item_id, i.i_product_name
),
combined AS (
    SELECT
        s.d_year,
        s.d_month_seq,
        s.channel,
        s.region_state,
        s.i_item_id,
        s.i_product_name,
        s.net_paid,
        s.net_profit,
        s.quantity,
        COALESCE(r.net_loss, 0) AS net_loss,
        COALESCE(r.return_qty, 0) AS return_qty,
        s.net_paid - COALESCE(r.net_loss, 0) AS net_contribution
    FROM sales s
    LEFT JOIN returns r
        ON s.d_year = r.d_year
       AND s.d_month_seq = r.d_month_seq
       AND s.channel = r.channel
       AND s.region_state = r.region_state
       AND s.i_item_id = r.i_item_id
),
ranked AS (
    SELECT
        *,
        row_number() OVER (PARTITION BY d_year, d_month_seq, region_state, channel ORDER BY net_contribution DESC) AS item_rank,
        sum(net_contribution) OVER (PARTITION BY d_year, d_month_seq, region_state, channel) AS region_total_contribution,
        sum(net_contribution) OVER (PARTITION BY d_year, d_month_seq, channel) AS channel_total_contribution,
        sum(net_contribution) OVER (
            PARTITION BY d_year, d_month_seq, region_state, channel
            ORDER BY net_contribution
            ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
        ) AS cumulative_region_contribution
    FROM combined
)
SELECT
    d_year,
    d_month_seq,
    channel,
    region_state,
    i_item_id,
    i_product_name,
    net_paid,
    net_profit,
    quantity,
    net_loss,
    return_qty,
    net_contribution,
    round((net_contribution / nullif(net_paid, 0)) * 100, 2) AS net_contrib_pct,
    region_total_contribution,
    channel_total_contribution,
    round((net_contribution / nullif(region_total_contribution, 0)) * 100, 2) AS pct_of_region,
    round((net_contribution / nullif(channel_total_contribution, 0)) * 100, 2) AS pct_of_channel,
    item_rank,
    cumulative_region_contribution
FROM ranked
WHERE d_year = 2001
  AND item_rank <= 10
ORDER BY d_year, d_month_seq, channel, region_state, item_rank
LIMIT 200
